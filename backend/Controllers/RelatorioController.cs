// RelatorioController — Dados calculados em tempo real + Exportação Excel/PDF (US14) + Top Clientes (RF08/US15)
using MaxiMassasAPI.DTOs.Common;
using MaxiMassasAPI.DTOs.Relatorio;
using MaxiMassasAPI.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace MaxiMassasAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Roles = "Administrador")]
[Produces("application/json")]
public class RelatorioController : ControllerBase
{
    private readonly IRelatorioService _svc;
    private readonly IExportacaoService _exportSvc;

    public RelatorioController(IRelatorioService svc, IExportacaoService exportSvc)
    {
        _svc = svc;
        _exportSvc = exportSvc;
    }

    // =========================================================================
    // Endpoints existentes (mantidos sem alteração)
    // =========================================================================

    [HttpGet("faturamento")]
    public async Task<IActionResult> Faturamento([FromQuery] DateTime inicio, [FromQuery] DateTime fim)
        => Ok(ApiResponse<FaturamentoPorPeriodoDto>.Ok(await _svc.GetFaturamentoPorPeriodoAsync(inicio, fim)));

    [HttpGet("lucro")]
    public async Task<IActionResult> Lucro([FromQuery] DateTime inicio, [FromQuery] DateTime fim)
        => Ok(ApiResponse<LucroPorPeriodoDto>.Ok(await _svc.GetLucroPorPeriodoAsync(inicio, fim)));

    [HttpGet("ticket-medio")]
    public async Task<IActionResult> TicketMedio([FromQuery] DateTime inicio, [FromQuery] DateTime fim)
        => Ok(ApiResponse<decimal>.Ok(await _svc.GetTicketMedioAsync(inicio, fim)));

    [HttpGet("produtos-mais-vendidos")]
    public async Task<IActionResult> ProdutosMaisVendidos([FromQuery] DateTime inicio, [FromQuery] DateTime fim, [FromQuery] int top = 10)
        => Ok(ApiResponse<IEnumerable<ProdutoMaisVendidoDto>>.Ok(await _svc.GetProdutosMaisVendidosAsync(inicio, fim, top)));

    [HttpGet("historico-vendas")]
    public async Task<IActionResult> HistoricoVendas([FromQuery] DateTime inicio, [FromQuery] DateTime fim)
        => Ok(ApiResponse<IEnumerable<HistoricoVendaDto>>.Ok(await _svc.GetHistoricoVendasAsync(inicio, fim)));

    [HttpGet("financeiro")]
    public async Task<IActionResult> Financeiro([FromQuery] DateTime inicio, [FromQuery] DateTime fim)
        => Ok(ApiResponse<RelatorioFinanceiroDto>.Ok(await _svc.GetRelatorioFinanceiroAsync(inicio, fim)));

    // =========================================================================
    // RF08 / US15 — Top 5 Clientes por Valor Gasto
    // GET /api/relatorio/top-clientes?inicio=2024-01-01&fim=2024-12-31&top=5
    // =========================================================================

    /// <summary>
    /// Retorna o ranking dos clientes com maior valor gasto no período.
    /// Ordenado por TotalGasto decrescente, limitado ao top N (padrão: 5).
    /// Vendas canceladas são excluídas do cálculo.
    /// </summary>
    [HttpGet("top-clientes")]
    public async Task<IActionResult> TopClientes(
        [FromQuery] DateTime inicio,
        [FromQuery] DateTime fim,
        [FromQuery] int top = 5)
    {
        if (inicio > fim)
            return BadRequest(ApiResponse.Fail("A data de início deve ser anterior à data de fim."));

        if (top < 1 || top > 50)
            return BadRequest(ApiResponse.Fail("O parâmetro 'top' deve estar entre 1 e 50."));

        var resultado = await _svc.GetTopClientesAsync(inicio, fim, top);
        return Ok(ApiResponse<IEnumerable<TopClienteDto>>.Ok(resultado,
            $"Top {top} clientes por valor gasto no período."));
    }

    // =========================================================================
    // US14 — Exportação de Relatórios
    // =========================================================================

    /// <summary>
    /// Exporta relatório completo em formato Excel (.xlsx).
    /// Inclui: Resumo Financeiro, Produtos Mais Vendidos, Histórico de Vendas e Top Clientes.
    /// Retorna o arquivo para download direto.
    /// </summary>
    [HttpGet("exportar/excel")]
    [Produces("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")]
    public async Task<IActionResult> ExportarExcel([FromQuery] DateTime inicio, [FromQuery] DateTime fim)
    {
        if (inicio > fim)
            return BadRequest(ApiResponse.Fail("A data de início deve ser anterior à data de fim."));

        var bytes = await _exportSvc.ExportarExcelAsync(inicio, fim);

        // Sugere nome do arquivo com o período para o navegador
        var nomeArquivo = $"MaxiMassas_Relatorio_{inicio:yyyyMMdd}_{fim:yyyyMMdd}.xlsx";

        // FileResult força download pelo browser com o Content-Disposition correto
        return File(bytes,
            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            nomeArquivo);
    }

    /// <summary>
    /// Exporta relatório completo em formato PDF.
    /// Inclui: Resumo Financeiro, Produtos Mais Vendidos e Top Clientes.
    /// Retorna o arquivo para download direto.
    /// </summary>
    [HttpGet("exportar/pdf")]
    [Produces("application/pdf")]
    public async Task<IActionResult> ExportarPdf([FromQuery] DateTime inicio, [FromQuery] DateTime fim)
    {
        if (inicio > fim)
            return BadRequest(ApiResponse.Fail("A data de início deve ser anterior à data de fim."));

        var bytes = await _exportSvc.ExportarPdfAsync(inicio, fim);

        var nomeArquivo = $"MaxiMassas_Relatorio_{inicio:yyyyMMdd}_{fim:yyyyMMdd}.pdf";

        return File(bytes, "application/pdf", nomeArquivo);
    }
}
