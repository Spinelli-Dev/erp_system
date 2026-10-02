// Dashboard: indicadores montados no servidor, pelos mesmos services dos relatórios da API.
// O período (mês/ano) vem na URL (?mes=10&ano=2026); trocar o filtro recarrega a página.
// Valores financeiros e rankings são só para Administrador (mesma regra da API /api/Relatorio);
// para os demais perfis aparecem como "—".
using MaxiMassasAPI.DTOs.Relatorio;
using MaxiMassasAPI.DTOs.Response;
using MaxiMassasAPI.Models;
using MaxiMassasAPI.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace MaxiMassasAPI.Pages;

public class DashboardModel : PageModel
{
    private readonly IRelatorioService _relatorios;
    private readonly IConsumoProprioService _consumo;
    private readonly IEstoqueService _estoque;
    private readonly IProdutoService _produtos;
    private readonly IVendaService _vendas;

    public DashboardModel(IRelatorioService relatorios, IConsumoProprioService consumo, IEstoqueService estoque,
        IProdutoService produtos, IVendaService vendas)
    {
        _relatorios = relatorios;
        _consumo = consumo;
        _estoque = estoque;
        _produtos = produtos;
        _vendas = vendas;
    }

    [BindProperty(SupportsGet = true)] public int? Mes { get; set; }
    [BindProperty(SupportsGet = true)] public int? Ano { get; set; }

    public bool VeFinanceiro => User.IsInRole(nameof(TipoUsuario.Administrador));

    public RelatorioFinanceiroDto? Hoje { get; private set; }
    public RelatorioFinanceiroDto? Periodo { get; private set; }
    public int? ConsumidosNoPeriodo { get; private set; }
    public decimal? LucroHistorico { get; private set; }
    public IReadOnlyList<(string Nome, int Quantidade)> EstoqueBaixo { get; private set; } = Array.Empty<(string, int)>();
    public IReadOnlyList<VendaResponse> EntregasHoje { get; private set; } = Array.Empty<VendaResponse>();
    public IReadOnlyList<TopClienteDto> TopClientes { get; private set; } = Array.Empty<TopClienteDto>();
    public IReadOnlyList<ProdutoMaisVendidoDto> TopProdutos { get; private set; } = Array.Empty<ProdutoMaisVendidoDto>();
    public IReadOnlyList<int> Anos { get; private set; } = Array.Empty<int>();

    public async Task OnGetAsync()
    {
        var hoje = DateTime.Today;
        Mes = Mes is >= 1 and <= 12 ? Mes : hoje.Month;
        Ano = Ano is >= 2000 and <= 2100 ? Ano : hoje.Year;
        Anos = Enumerable.Range(hoje.Year - 2, 3).Append(Ano.Value).Distinct().OrderBy(a => a).ToList();

        var inicioMes = new DateTime(Ano.Value, Mes.Value, 1);
        var fimMes = inicioMes.AddMonths(1).AddTicks(-1);
        var fimHoje = hoje.AddDays(1).AddTicks(-1);

        if (VeFinanceiro)
        {
            Hoje = await _relatorios.GetRelatorioFinanceiroAsync(hoje, fimHoje);
            Periodo = await _relatorios.GetRelatorioFinanceiroAsync(inicioMes, fimMes);
            ConsumidosNoPeriodo = (await _consumo.GetByPeriodoAsync(inicioMes, fimMes)).Sum(c => c.Quantidade);
            LucroHistorico = (await _relatorios.GetLucroPorPeriodoAsync(new DateTime(2000, 1, 1), fimMes)).LucroBruto;
            TopClientes = (await _relatorios.GetTopClientesAsync(inicioMes, fimMes, 3)).ToList();
            TopProdutos = (await _relatorios.GetProdutosMaisVendidosAsync(inicioMes, fimMes, 5)).ToList();
        }

        var nomes = (await _produtos.GetAllAsync())
            .ToDictionary(p => p.Id, p => string.IsNullOrEmpty(p.Sabor) ? p.Nome : $"{p.Nome} {p.Sabor}");
        EstoqueBaixo = (await _estoque.GetEstoquesBaixosAsync())
            .OrderBy(e => e.Quantidade)
            .Select(e => (nomes.GetValueOrDefault(e.ProdutoId, $"Produto #{e.ProdutoId}"), e.Quantidade))
            .ToList();
        EntregasHoje = (await _vendas.GetAllAsync())
            .Where(v => v.Entrega is not null && v.Entrega.DataEntrega.Date == hoje && v.Status != StatusVenda.Cancelada)
            .OrderBy(v => v.Entrega!.Horario)
            .ToList();
    }

    public static string Margem(RelatorioFinanceiroDto? r) =>
        r is null ? "—" : r.TotalFaturado > 0 ? $"{r.LucroBruto / r.TotalFaturado * 100:0}%" : "0%";

    public static string Dinheiro(decimal? valor) => valor is null ? "—" : PainelFormatos.Moeda(valor.Value);
}
