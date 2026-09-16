using MaxiMassasAPI.DTOs.Relatorio;

namespace MaxiMassasAPI.Services;

public interface IRelatorioService
{
    Task<FaturamentoPorPeriodoDto> GetFaturamentoPorPeriodoAsync(DateTime inicio, DateTime fim);
    Task<LucroPorPeriodoDto> GetLucroPorPeriodoAsync(DateTime inicio, DateTime fim);
    Task<decimal> GetTicketMedioAsync(DateTime inicio, DateTime fim);
    Task<IEnumerable<ProdutoMaisVendidoDto>> GetProdutosMaisVendidosAsync(DateTime inicio, DateTime fim, int top = 10);
    Task<IEnumerable<HistoricoVendaDto>> GetHistoricoVendasAsync(DateTime inicio, DateTime fim);
    Task<RelatorioFinanceiroDto> GetRelatorioFinanceiroAsync(DateTime inicio, DateTime fim);

    // RF08 / US15 — Ranking de clientes por valor gasto
    /// <summary>Retorna os clientes com maior volume de compras no período, limitado ao top N.</summary>
    Task<IEnumerable<TopClienteDto>> GetTopClientesAsync(DateTime inicio, DateTime fim, int top = 5);
}