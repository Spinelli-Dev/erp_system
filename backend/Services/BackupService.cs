// RNF03 — Backup Automático do Banco de Dados
// Implementado como BackgroundService (IHostedService) do .NET
// Executa em background de forma assíncrona, sem bloquear a API
// Configurado via appsettings.json na seção "Backup"
using Microsoft.Data.SqlClient;

namespace MaxiMassasAPI.Services;

/// <summary>
/// Serviço de background que realiza backup automático do SQL Server.
///
/// FUNCIONAMENTO:
///   - Executa T-SQL BACKUP DATABASE para criar um arquivo .bak
///   - Respeita intervalo configurado (padrão: 24 horas)
///   - Salva em diretório configurável no appsettings.json
///   - Nome do arquivo inclui data/hora para identificação
///   - Loga início, conclusão e erros via ILogger
///
/// CONFIGURAÇÃO (appsettings.json):
/// "Backup": {
///   "DiretorioDestino": "C:\\Backups\\MaxiMassas",
///   "IntervaloDias": 1,
///   "HorarioExecucao": "02:00",
///   "ManterUltimosN": 7
/// }
///
/// ATENÇÃO: O SQL Server precisa ter permissão de escrita no diretório de destino.
/// Em produção, o serviço de SQL Server deve ter acesso ao caminho configurado.
/// </summary>
public class BackupService : BackgroundService
{
    private readonly IServiceProvider _serviceProvider;
    private readonly IConfiguration _config;
    private readonly ILogger<BackupService> _logger;

    // Configurações lidas do appsettings.json
    private readonly string _diretorioDestino;
    private readonly int _intervaloDias;
    private readonly TimeSpan _horarioExecucao;
    private readonly int _manterUltimosN;
    private readonly string _connectionString;

    public BackupService(
        IServiceProvider serviceProvider,
        IConfiguration config,
        ILogger<BackupService> logger)
    {
        _serviceProvider = serviceProvider;
        _config = config;
        _logger = logger;

        var section = config.GetSection("Backup");
        _diretorioDestino = section["DiretorioDestino"] ?? Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "Backups");
        _intervaloDias = section.GetValue<int>("IntervaloDias", 1);
        _manterUltimosN = section.GetValue<int>("ManterUltimosN", 7);
        _connectionString = config.GetConnectionString("DefaultConnection")
            ?? throw new InvalidOperationException("ConnectionString 'DefaultConnection' não configurada.");

        // Horário de execução (ex: "02:00" = 2h da madrugada)
        var horarioStr = section["HorarioExecucao"] ?? "02:00";
        _horarioExecucao = TimeSpan.TryParse(horarioStr, out var ts) ? ts : TimeSpan.FromHours(2);
    }

    /// <summary>
    /// Loop principal do background service.
    /// Calcula quando deve rodar o próximo backup e aguarda até lá.
    /// </summary>
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation(
            "[Backup] Serviço iniciado. Diretório: {Dir} | Intervalo: {Dias} dias | Horário: {Hora}",
            _diretorioDestino, _intervaloDias, _horarioExecucao);

        // Garante que o diretório de backup existe
        Directory.CreateDirectory(_diretorioDestino);

        while (!stoppingToken.IsCancellationRequested)
        {
            var agora = DateTime.Now;
            // Próxima execução = hoje no horário configurado; se já passou, amanhã
            var proximaExecucao = agora.Date.Add(_horarioExecucao);
            if (proximaExecucao <= agora)
                proximaExecucao = proximaExecucao.AddDays(_intervaloDias);

            var espera = proximaExecucao - agora;
            _logger.LogInformation(
                "[Backup] Próximo backup agendado para: {Data} ({Espera:hh\\:mm\\:ss} horas)",
                proximaExecucao, espera);

            try
            {
                // Aguarda até o horário do próximo backup (cancelável)
                await Task.Delay(espera, stoppingToken);

                // Executa o backup
                await RealizarBackupAsync(stoppingToken);

                // Limpa backups antigos (mantém apenas os N mais recentes)
                LimparBackupsAntigos();
            }
            catch (OperationCanceledException)
            {
                // Aplicação foi encerrada — saída limpa do loop
                _logger.LogInformation("[Backup] Serviço encerrado por cancellation token.");
                break;
            }
            catch (Exception ex)
            {
                // Erro inesperado: loga e aguarda 1 hora antes de tentar novamente
                _logger.LogError(ex, "[Backup] Erro inesperado. Nova tentativa em 1 hora.");
                await Task.Delay(TimeSpan.FromHours(1), stoppingToken);
            }
        }
    }

    /// <summary>
    /// Executa o comando BACKUP DATABASE do SQL Server via ADO.NET.
    /// Gera arquivo .bak com nome contendo data/hora.
    /// </summary>
    private async Task RealizarBackupAsync(CancellationToken ct)
    {
        // Nome do arquivo inclui timestamp para identificação única
        var timestamp = DateTime.Now.ToString("yyyyMMdd_HHmmss");
        var nomeArquivo = $"MaxiMassas_Backup_{timestamp}.bak";
        var caminhoCompleto = Path.Combine(_diretorioDestino, nomeArquivo);

        _logger.LogInformation("[Backup] Iniciando backup → {Arquivo}", caminhoCompleto);

        try
        {
            // T-SQL nativo do SQL Server para backup completo
            // WITH COMPRESSION: reduz tamanho do arquivo
            // WITH STATS=10: reporta progresso a cada 10%
            var sql = $@"
                BACKUP DATABASE [{ObterNomeBancoDados()}]
                TO DISK = N'{caminhoCompleto}'
                WITH COMPRESSION, STATS = 10, NAME = N'MaxiMassas-Full-{timestamp}';
            ";

            using var connection = new SqlConnection(_connectionString);
            await connection.OpenAsync(ct);

            using var command = new SqlCommand(sql, connection)
            {
                // Timeout generoso para bancos maiores (5 minutos)
                CommandTimeout = 300
            };

            await command.ExecuteNonQueryAsync(ct);

            _logger.LogInformation(
                "[Backup] ✅ Backup concluído com sucesso! Arquivo: {Arquivo} ({Tamanho} MB)",
                nomeArquivo,
                Math.Round(new FileInfo(caminhoCompleto).Length / 1_048_576.0, 2));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "[Backup] ❌ Falha ao realizar backup. Arquivo: {Arquivo}", caminhoCompleto);
            throw;
        }
    }

    /// <summary>
    /// Remove os backups mais antigos, mantendo apenas os N mais recentes.
    /// Configurado via "Backup:ManterUltimosN" no appsettings.json.
    /// </summary>
    private void LimparBackupsAntigos()
    {
        try
        {
            var arquivos = Directory.GetFiles(_diretorioDestino, "MaxiMassas_Backup_*.bak")
                .Select(f => new FileInfo(f))
                .OrderByDescending(f => f.CreationTime)
                .ToList();

            // Mantém os N mais recentes e remove o resto
            var paraRemover = arquivos.Skip(_manterUltimosN).ToList();
            foreach (var arquivo in paraRemover)
            {
                arquivo.Delete();
                _logger.LogInformation("[Backup] 🗑 Backup antigo removido: {Arquivo}", arquivo.Name);
            }

            if (paraRemover.Count > 0)
                _logger.LogInformation("[Backup] Limpeza concluída. {N} arquivo(s) removido(s).", paraRemover.Count);
        }
        catch (Exception ex)
        {
            // Falha na limpeza não deve interromper o serviço
            _logger.LogWarning(ex, "[Backup] Falha ao limpar backups antigos.");
        }
    }

    /// <summary>
    /// Extrai o nome do banco de dados a partir da connection string.
    /// Necessário para montar o comando T-SQL de backup.
    /// </summary>
    private string ObterNomeBancoDados()
    {
        var builder = new SqlConnectionStringBuilder(_connectionString);
        return builder.InitialCatalog;
    }
}
