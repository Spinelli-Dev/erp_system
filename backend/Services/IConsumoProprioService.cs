// RF04 — Contrato do service de Consumo Próprio
using MaxiMassasAPI.DTOs.Request;
using MaxiMassasAPI.DTOs.Response;

namespace MaxiMassasAPI.Services;

/// <summary>
/// Contrato para operações de Consumo Próprio.
/// O consumo reduz estoque mas NÃO gera venda nem movimentação financeira.
/// </summary>
public interface IConsumoProprioService
{
    /// <summary>Lista todos os consumos com detalhes (produto, usuário).</summary>
    Task<IEnumerable<ConsumoProprioResponse>> GetAllAsync();

    /// <summary>Lista consumos filtrados por período.</summary>
    Task<IEnumerable<ConsumoProprioResponse>> GetByPeriodoAsync(DateTime inicio, DateTime fim);

    /// <summary>Lista consumos de um produto específico.</summary>
    Task<IEnumerable<ConsumoProprioResponse>> GetByProdutoIdAsync(int produtoId);

    /// <summary>
    /// Registra novo consumo interno.
    /// Valida estoque, baixa quantidade e grava histórico separado.
    /// </summary>
    /// <param name="request">Dados do consumo.</param>
    /// <param name="usuarioId">ID do usuário autenticado (extraído do contexto HTTP).</param>
    Task<ConsumoProprioResponse> RegistrarConsumoAsync(ConsumoProprioRequest request, int usuarioId);
}
