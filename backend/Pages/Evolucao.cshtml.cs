// Evolução: as séries dos gráficos são calculadas no servidor para os quatro períodos da tela
// (Dia do Mês, Semana, Mês, Ano) e embutidas na página; o evolucao.js só desenha com Chart.js.
// Dados financeiros e exportação (Excel/PDF) só para Administrador (mesma regra da API /api/Relatorio).
using System.Text.Json;
using MaxiMassasAPI.DTOs.Response;
using MaxiMassasAPI.Models;
using MaxiMassasAPI.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace MaxiMassasAPI.Pages;

public class EvolucaoModel : PageModel
{
    private readonly IVendaService _vendas;
    private readonly IProdutoService _produtos;
    private readonly IRelatorioService _relatorios;
    private readonly IExportacaoService _exportacao;

    public EvolucaoModel(IVendaService vendas, IProdutoService produtos, IRelatorioService relatorios, IExportacaoService exportacao)
    {
        _exportacao = exportacao;
        _vendas = vendas;
        _produtos = produtos;
        _relatorios = relatorios;
    }

    public bool VeFinanceiro => User.IsInRole(nameof(TipoUsuario.Administrador));

    /// <summary>{ "Mês": { labels, receita, lucro, produtos: [{ nome, faturado, quantidade }] }, ... }</summary>
    public string DadosJson { get; private set; } = "{}";

    private static readonly string[] NomesMes = { "Jan", "Fev", "Mar", "Abr", "Mai", "Jun", "Jul", "Ago", "Set", "Out", "Nov", "Dez" };

    public async Task OnGetAsync()
    {
        if (!VeFinanceiro) return;

        var hoje = DateTime.Today;
        var custo = (await _produtos.GetAllAsync()).ToDictionary(p => p.Id, p => p.Custo);
        // Canceladas não são receita.
        var vendas = (await _vendas.GetAllAsync()).Where(v => v.Status != StatusVenda.Cancelada).ToList();
        decimal Lucro(VendaResponse v) => v.Itens.Sum(i => i.Subtotal - custo.GetValueOrDefault(i.ProdutoId) * i.Quantidade);

        var inicioMes = new DateTime(hoje.Year, hoje.Month, 1);
        var fimMes = inicioMes.AddMonths(1).AddTicks(-1);
        var noMes = vendas.Where(v => v.Data >= inicioMes && v.Data <= fimMes).ToList();
        var noAno = vendas.Where(v => v.Data.Year == hoje.Year).ToList();
        var diasNoMes = DateTime.DaysInMonth(hoje.Year, hoje.Month);
        var anos = Enumerable.Range(hoje.Year - 3, 4).ToList();

        var dados = new Dictionary<string, object>
        {
            ["Dia do Mês"] = await SerieAsync(
                Enumerable.Range(1, diasNoMes).Select(d => d.ToString("00")).ToList(),
                noMes, v => v.Data.Day.ToString("00"), Lucro, inicioMes, fimMes),
            ["Semana"] = await SerieAsync(
                Enumerable.Range(1, 5).Select(s => $"Semana {s}").ToList(),
                noMes, v => $"Semana {(v.Data.Day + 6) / 7}", Lucro, inicioMes, fimMes),
            ["Mês"] = await SerieAsync(
                NomesMes.ToList(), noAno, v => NomesMes[v.Data.Month - 1], Lucro,
                new DateTime(hoje.Year, 1, 1), new DateTime(hoje.Year, 12, 31, 23, 59, 59)),
            ["Ano"] = await SerieAsync(
                anos.Select(a => a.ToString()).ToList(),
                vendas.Where(v => v.Data.Year >= anos[0]).ToList(), v => v.Data.Year.ToString(), Lucro,
                new DateTime(anos[0], 1, 1), new DateTime(hoje.Year, 12, 31, 23, 59, 59)),
        };
        DadosJson = JsonSerializer.Serialize(dados);
    }

    // ── Exportar relatório (US14): Excel e PDF do período escolhido, só para Administrador ──

    /// <summary>Período padrão do formulário: do dia 1 do mês até hoje.</summary>
    public DateTime ExportarInicio => new(DateTime.Today.Year, DateTime.Today.Month, 1);
    public DateTime ExportarFim => DateTime.Today;

    /// <summary>Erro de período (ex.: início depois do fim); a página volta com a mensagem.</summary>
    public string? ErroExportacao { get; private set; }

    public Task<IActionResult> OnGetExcelAsync(DateTime? inicio, DateTime? fim)
        => ExportarAsync(inicio, fim, "xlsx", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            (i, f) => _exportacao.ExportarExcelAsync(i, f));

    public Task<IActionResult> OnGetPdfAsync(DateTime? inicio, DateTime? fim)
        => ExportarAsync(inicio, fim, "pdf", "application/pdf", (i, f) => _exportacao.ExportarPdfAsync(i, f));

    private async Task<IActionResult> ExportarAsync(DateTime? inicio, DateTime? fim, string extensao, string tipo,
        Func<DateTime, DateTime, Task<byte[]>> gerar)
    {
        if (!VeFinanceiro) return RedirectToPage(); // operador: sem botão e sem download (Forbid mandaria para o login)

        ErroExportacao = (inicio, fim) switch
        {
            (null, _) or (_, null) => "Informe o início e o fim do período.",
            var (i, f) when i > f => "A data de início deve ser anterior à data de fim.",
            var (i, f) when (f!.Value - i!.Value).TotalDays > 366 * 5 => "Escolha um período de até 5 anos.",
            _ => null
        };
        if (ErroExportacao is not null)
        {
            await OnGetAsync(); // remonta os gráficos para mostrar a página com o aviso
            return Page();
        }

        var bytes = await gerar(inicio!.Value.Date, fim!.Value.Date);
        return File(bytes, tipo, $"MaxiMassas_Relatorio_{inicio:yyyyMMdd}_{fim:yyyyMMdd}.{extensao}");
    }

    private async Task<object> SerieAsync(List<string> rotulos, List<VendaResponse> vendas, Func<VendaResponse, string> chave,
        Func<VendaResponse, decimal> lucro, DateTime inicio, DateTime fim)
    {
        var porChave = vendas.GroupBy(chave).ToDictionary(g => g.Key, g => (Receita: g.Sum(v => v.ValorTotal), Lucro: g.Sum(lucro)));
        var produtos = await _relatorios.GetProdutosMaisVendidosAsync(inicio, fim, 12);
        return new
        {
            labels = rotulos,
            receita = rotulos.Select(r => porChave.TryGetValue(r, out var x) ? x.Receita : 0),
            lucro = rotulos.Select(r => porChave.TryGetValue(r, out var x) ? x.Lucro : 0),
            produtos = produtos.Select(p => new { nome = p.NomeProduto, faturado = p.TotalFaturado, quantidade = p.QuantidadeVendida })
        };
    }
}
