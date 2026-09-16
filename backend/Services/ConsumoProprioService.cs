// RF04 — Implementação do Service de Consumo Próprio
using MaxiMassasAPI.DTOs.Request;
using MaxiMassasAPI.DTOs.Response;
using MaxiMassasAPI.Models;
using MaxiMassasAPI.Repositories;

namespace MaxiMassasAPI.Services;

/// <summary>
/// Orquestra o consumo interno de produtos pelos proprietários.
///
/// FLUXO:
///   1. Busca estoque do produto informado
///   2. Valida se há quantidade suficiente
///   3. Deduz a quantidade do estoque (TipoMovimentacao.Saida)
///   4. Grava registro na tabela ConsumoProprio (histórico separado)
///   5. Retorna DTO com estoque restante informativo
///
/// IMPORTANTE: Não cria Venda, não altera saldo financeiro.
/// </summary>
public class ConsumoProprioService : IConsumoProprioService
{
    private readonly IConsumoProprioRepository _consumoRepo;
    private readonly IEstoqueRepository _estoqueRepo;
    private readonly IRepository<MovimentacaoEstoque> _movRepo;
    private readonly ILogger<ConsumoProprioService> _logger;

    public ConsumoProprioService(
        IConsumoProprioRepository consumoRepo,
        IEstoqueRepository estoqueRepo,
        IRepository<MovimentacaoEstoque> movRepo,
        ILogger<ConsumoProprioService> logger)
    {
        _consumoRepo = consumoRepo;
        _estoqueRepo = estoqueRepo;
        _movRepo = movRepo;
        _logger = logger;
    }

    /// <inheritdoc/>
    public async Task<IEnumerable<ConsumoProprioResponse>> GetAllAsync()
    {
        var consumos = await _consumoRepo.GetAllComDetalhesAsync();
        return consumos.Select(MapToResponse);
    }

    /// <inheritdoc/>
    public async Task<IEnumerable<ConsumoProprioResponse>> GetByPeriodoAsync(DateTime inicio, DateTime fim)
    {
        var consumos = await _consumoRepo.GetByPeriodoAsync(inicio, fim);
        return consumos.Select(MapToResponse);
    }

    /// <inheritdoc/>
    public async Task<IEnumerable<ConsumoProprioResponse>> GetByProdutoIdAsync(int produtoId)
    {
        var consumos = await _consumoRepo.GetByProdutoIdAsync(produtoId);
        return consumos.Select(MapToResponse);
    }

    /// <inheritdoc/>
    public async Task<ConsumoProprioResponse> RegistrarConsumoAsync(ConsumoProprioRequest request, int usuarioId)
    {
        // 1. Busca o estoque vinculado ao produto
        var estoque = await _estoqueRepo.GetByProdutoIdAsync(request.ProdutoId)
            ?? throw new KeyNotFoundException($"Produto ID {request.ProdutoId} não possui estoque cadastrado.");

        // 2. Validação de negócio: quantidade disponível deve ser suficiente
        if (request.Quantidade <= 0)
            throw new InvalidOperationException("A quantidade deve ser maior que zero.");

        if (estoque.Quantidade < request.Quantidade)
            throw new InvalidOperationException(
                $"Estoque insuficiente para consumo próprio. Disponível: {estoque.Quantidade}, Solicitado: {request.Quantidade}.");

        // 3. Deduz do estoque (sem gerar venda)
        estoque.Quantidade -= request.Quantidade;
        _estoqueRepo.Update(estoque);

        // 4. Registra movimentação de saída de estoque com motivo "Consumo Próprio"
        //    Isso mantém rastreabilidade no histórico de movimentações
        var movimentacao = new MovimentacaoEstoque
        {
            EstoqueId = estoque.Id,
            Tipo = TipoMovimentacao.Saida,
            Quantidade = request.Quantidade,
            Motivo = $"Consumo Próprio — {request.Observacao ?? "Sem observação"}",
            Data = DateTime.Now
        };
        await _movRepo.AddAsync(movimentacao);

        // 5. Cria o registro de ConsumoProprio (tabela separada para histórico dedicado)
        var consumo = new ConsumoProprio
        {
            ProdutoId = request.ProdutoId,
            Quantidade = request.Quantidade,
            UsuarioId = usuarioId,
            Observacao = request.Observacao,
            Data = DateTime.Now
        };
        await _consumoRepo.AddAsync(consumo);

        // 6. Persiste tudo em uma única transação (SaveChanges do contexto compartilhado)
        await _consumoRepo.SaveChangesAsync();

        // 7. Alerta no log se estoque ficou abaixo do mínimo
        if (estoque.Quantidade <= estoque.AlertaMinimo)
            _logger.LogWarning(
                "[ConsumoProprio] Estoque baixo após consumo. ProdutoId={ProdutoId}, Qtd={Qtd}, AlertaMinimo={Min}",
                estoque.ProdutoId, estoque.Quantidade, estoque.AlertaMinimo);

        _logger.LogInformation(
            "[ConsumoProprio] Consumo registrado. ProdutoId={ProdutoId}, Qtd={Qtd}, UsuarioId={UserId}",
            request.ProdutoId, request.Quantidade, usuarioId);

        // 8. Retorna resposta enriquecida (carrega produto para ter o nome)
        var produtoNome = estoque.Produto?.Nome ?? "N/A";

        return new ConsumoProprioResponse
        {
            Id = consumo.Id,
            Data = consumo.Data,
            ProdutoId = consumo.ProdutoId,
            NomeProduto = produtoNome,
            Quantidade = consumo.Quantidade,
            UsuarioId = consumo.UsuarioId,
            NomeUsuario = string.Empty, // preenchido no controller via User.Identity
            Observacao = consumo.Observacao,
            EstoqueRestante = estoque.Quantidade
        };
    }

    // -------------------------------------------------------------------------
    // Mapeamento interno: entidade → DTO de resposta
    // Evita dependência de AutoMapper para mapeamentos triviais aqui,
    // mantendo a lógica de negócio explícita e legível.
    // -------------------------------------------------------------------------
    private static ConsumoProprioResponse MapToResponse(ConsumoProprio c) => new()
    {
        Id = c.Id,
        Data = c.Data,
        ProdutoId = c.ProdutoId,
        NomeProduto = c.Produto?.Nome ?? "N/A",
        Quantidade = c.Quantidade,
        UsuarioId = c.UsuarioId,
        NomeUsuario = c.Usuario?.Nome ?? "N/A",
        Observacao = c.Observacao,
        EstoqueRestante = 0 // não consultado em listagens para performance
    };
}
