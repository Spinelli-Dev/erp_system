// Leitura e alteração da regra de taxa de entrega (registro único em ConfiguracoesEntrega).
// Usado pela tela de Entregas do sistema web (gestores) e pelos pedidos do app.
using MaxiMassasAPI.DTOs.Request;
using MaxiMassasAPI.DTOs.Response;
using MaxiMassasAPI.Models;
using MaxiMassasAPI.Repositories;

namespace MaxiMassasAPI.Services;

public interface IConfiguracaoEntregaService
{
    Task<ConfiguracaoEntrega> ObterAsync();
    Task<ConfiguracaoEntregaResponse> ObterResponseAsync();
    Task<ConfiguracaoEntregaResponse> AtualizarAsync(ConfiguracaoEntregaRequest request);
}

public class ConfiguracaoEntregaService : IConfiguracaoEntregaService
{
    private readonly IRepository<ConfiguracaoEntrega> _repo;
    private readonly ILogger<ConfiguracaoEntregaService> _logger;

    public ConfiguracaoEntregaService(IRepository<ConfiguracaoEntrega> repo, ILogger<ConfiguracaoEntregaService> logger)
    {
        _repo = repo;
        _logger = logger;
    }

    /// <summary>Sempre devolve uma configuração: se o registro sumiu do banco, recria zerado.</summary>
    public async Task<ConfiguracaoEntrega> ObterAsync()
    {
        var config = await _repo.GetByIdAsync(ConfiguracaoEntrega.IdUnico);
        if (config is not null) return config;

        config = new ConfiguracaoEntrega();
        await _repo.AddAsync(config);
        await _repo.SaveChangesAsync();
        return config;
    }

    public async Task<ConfiguracaoEntregaResponse> ObterResponseAsync() => ParaResponse(await ObterAsync());

    public async Task<ConfiguracaoEntregaResponse> AtualizarAsync(ConfiguracaoEntregaRequest request)
    {
        var config = await ObterAsync();
        config.TaxaEntrega = request.TaxaEntrega;
        config.PedidoMinimoEntregaGratis = request.PedidoMinimoEntregaGratis;
        config.AtualizadoEm = DateTime.Now;
        await _repo.SaveChangesAsync();

        _logger.LogInformation("[Entrega] Taxa atualizada: {Taxa} | entrega gratis a partir de {Minimo}",
            config.TaxaEntrega, config.PedidoMinimoEntregaGratis);
        return ParaResponse(config);
    }

    private static ConfiguracaoEntregaResponse ParaResponse(ConfiguracaoEntrega c) => new()
    {
        TaxaEntrega = c.TaxaEntrega,
        PedidoMinimoEntregaGratis = c.PedidoMinimoEntregaGratis,
        AtualizadoEm = c.AtualizadoEm
    };
}
