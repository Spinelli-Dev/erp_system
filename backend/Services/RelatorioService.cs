// RelatorioService — atualizado para usar Venda.Status (UML) em vez de Venda.StatusPagamento.
// StatusPagamento agora pertence à entidade Pagamento.
using MaxiMassasAPI.Data;
using MaxiMassasAPI.DTOs.Relatorio;
using MaxiMassasAPI.Models;
using Microsoft.EntityFrameworkCore;

namespace MaxiMassasAPI.Services;

public class RelatorioService : IRelatorioService
{
    private readonly AppDbContext _context;

    public RelatorioService(AppDbContext context) { _context = context; }

    // Helper: normaliza período para início e fim do dia
    private static (DateTime inicio, DateTime fim) NormalizarPeriodo(DateTime inicio, DateTime fim)
        => (inicio.Date, fim.Date.AddDays(1));

    public async Task<FaturamentoPorPeriodoDto> GetFaturamentoPorPeriodoAsync(DateTime inicio, DateTime fim)
    {
        var (ini, fimD) = NormalizarPeriodo(inicio, fim);

        // UML: usa Venda.Status para filtrar canceladas (StatusVenda.Cancelada)
        var vendas = await _context.Vendas.AsNoTracking()
            .Where(v => v.Data >= ini && v.Data < fimD && v.Status != StatusVenda.Cancelada)
            .ToListAsync();

        return new FaturamentoPorPeriodoDto
        {
            DataInicio = ini, DataFim = fim,
            TotalFaturado = vendas.Sum(v => v.ValorTotal),
            TotalVendas = vendas.Count
        };
    }

    public async Task<LucroPorPeriodoDto> GetLucroPorPeriodoAsync(DateTime inicio, DateTime fim)
    {
        var (ini, fimD) = NormalizarPeriodo(inicio, fim);

        var itens = await _context.ItensVenda.AsNoTracking()
            .Include(i => i.Venda).Include(i => i.Produto)
            .Where(i => i.Venda.Data >= ini && i.Venda.Data < fimD
                     && i.Venda.Status != StatusVenda.Cancelada) // UML: filtro por StatusVenda
            .ToListAsync();

        var faturamento = itens.Sum(i => i.Subtotal);
        var custo = itens.Sum(i => i.Produto.Custo * i.Quantidade);
        var lucro = faturamento - custo;

        return new LucroPorPeriodoDto
        {
            DataInicio = ini, DataFim = fim,
            TotalFaturado = faturamento, TotalCusto = custo, LucroBruto = lucro,
            MargemLucro = faturamento > 0 ? Math.Round(lucro / faturamento * 100, 2) : 0
        };
    }

    public async Task<decimal> GetTicketMedioAsync(DateTime inicio, DateTime fim)
    {
        var (ini, fimD) = NormalizarPeriodo(inicio, fim);

        // Ticket médio apenas das vendas concluídas (pagamento confirmado)
        var vendas = await _context.Vendas.AsNoTracking()
            .Include(v => v.Pagamento)
            .Where(v => v.Data >= ini && v.Data < fimD
                     && v.Pagamento != null
                     && v.Pagamento.StatusPagamento == StatusPagamento.Pago) // UML: via Pagamento
            .ToListAsync();

        return vendas.Count > 0 ? vendas.Average(x => x.ValorTotal) : 0;
    }

    public async Task<IEnumerable<ProdutoMaisVendidoDto>> GetProdutosMaisVendidosAsync(DateTime inicio, DateTime fim, int top = 10)
    {
        var (ini, fimD) = NormalizarPeriodo(inicio, fim);

        return await _context.ItensVenda.AsNoTracking()
            .Include(i => i.Venda).Include(i => i.Produto)
            .Where(i => i.Venda.Data >= ini && i.Venda.Data < fimD
                     && i.Venda.Status != StatusVenda.Cancelada) // UML: StatusVenda
            .GroupBy(i => new { i.ProdutoId, i.Produto.Nome })
            .Select(g => new ProdutoMaisVendidoDto
            {
                ProdutoId = g.Key.ProdutoId,
                NomeProduto = g.Key.Nome,
                QuantidadeVendida = g.Sum(i => i.Quantidade),
                TotalFaturado = g.Sum(i => i.Subtotal)
            })
            .OrderByDescending(p => p.QuantidadeVendida)
            .Take(top)
            .ToListAsync();
    }

    public async Task<IEnumerable<HistoricoVendaDto>> GetHistoricoVendasAsync(DateTime inicio, DateTime fim)
    {
        var (ini, fimD) = NormalizarPeriodo(inicio, fim);

        return await _context.Vendas.AsNoTracking()
            .Include(v => v.Cliente)
            .Include(v => v.Pagamento)  // Carrega Pagamento para expor StatusPagamento
            .Where(v => v.Data >= ini && v.Data < fimD)
            .OrderByDescending(v => v.Data)
            .Select(v => new HistoricoVendaDto
            {
                VendaId = v.Id,
                Data = v.Data,
                NomeCliente = v.Cliente.Nome,
                ValorTotal = v.ValorTotal,
                // UML: Venda.Status (StatusVenda)
                StatusPagamento = v.Status.ToString(),
                Origem = v.Origem
            })
            .ToListAsync();
    }

    public async Task<RelatorioFinanceiroDto> GetRelatorioFinanceiroAsync(DateTime inicio, DateTime fim)
    {
        var (ini, fimD) = NormalizarPeriodo(inicio, fim);

        var vendas = await _context.Vendas.AsNoTracking()
            .Include(v => v.ItensVenda).ThenInclude(i => i.Produto)
            .Include(v => v.Pagamento)
            .Where(v => v.Data >= ini && v.Data < fimD)
            .ToListAsync();

        var ativas = vendas.Where(v => v.Status != StatusVenda.Cancelada).ToList();
        var faturamento = ativas.Sum(v => v.ValorTotal);
        var custo = ativas.SelectMany(v => v.ItensVenda).Sum(i => i.Produto.Custo * i.Quantidade);

        return new RelatorioFinanceiroDto
        {
            TotalFaturado = faturamento,
            TotalCusto = custo,
            LucroBruto = faturamento - custo,
            TicketMedio = ativas.Count > 0 ? ativas.Average(v => v.ValorTotal) : 0,
            TotalVendas = vendas.Count,
            // Usa StatusPagamento do Pagamento (UML) para contar pagas
            VendasPagas = vendas.Count(v => v.Pagamento?.StatusPagamento == StatusPagamento.Pago),
            VendasPendentes = vendas.Count(v => v.Pagamento?.StatusPagamento == StatusPagamento.Pendente),
            VendasCanceladas = vendas.Count(v => v.Status == StatusVenda.Cancelada)
        };
    }

    // RF08 / US15 — Top N Clientes por Valor Gasto
    public async Task<IEnumerable<TopClienteDto>> GetTopClientesAsync(DateTime inicio, DateTime fim, int top = 5)
    {
        var (ini, fimD) = NormalizarPeriodo(inicio, fim);

        var ranking = await _context.Vendas
            .AsNoTracking()
            .Include(v => v.Cliente)
            .Where(v => v.Data >= ini && v.Data < fimD && v.Status != StatusVenda.Cancelada)
            .GroupBy(v => new { v.ClienteId, v.Cliente.Nome })
            .Select(g => new TopClienteDto
            {
                ClienteId = g.Key.ClienteId,
                NomeCliente = g.Key.Nome,
                TotalGasto = g.Sum(v => v.ValorTotal),
                QuantidadeCompras = g.Count()
            })
            .OrderByDescending(c => c.TotalGasto)
            .Take(top)
            .ToListAsync();

        for (int i = 0; i < ranking.Count; i++)
            ranking[i].Posicao = i + 1;

        return ranking;
    }
}
