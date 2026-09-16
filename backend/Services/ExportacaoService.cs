// US14 — Serviço de Exportação de Relatórios
// Excel via ClosedXML (OpenXML sem dependências nativas)
// PDF via QuestPDF (fluent API, zero dependências nativas no Linux)
using ClosedXML.Excel;
using MaxiMassasAPI.Data;
using MaxiMassasAPI.DTOs.Relatorio;
using MaxiMassasAPI.Models;
using Microsoft.EntityFrameworkCore;
using QuestPDF.Fluent;
using QuestPDF.Helpers;
using QuestPDF.Infrastructure;

namespace MaxiMassasAPI.Services;

/// <summary>
/// Contrato para exportação de relatórios em diferentes formatos.
/// Reaproveitamos a lógica de dados do IRelatorioService — sem duplicar queries.
/// </summary>
public interface IExportacaoService
{
    /// <summary>Gera relatório completo em Excel (.xlsx).</summary>
    Task<byte[]> ExportarExcelAsync(DateTime inicio, DateTime fim);

    /// <summary>Gera relatório completo em PDF.</summary>
    Task<byte[]> ExportarPdfAsync(DateTime inicio, DateTime fim);
}

/// <summary>
/// Implementação da exportação de relatórios.
///
/// ESTRATÉGIA:
///   - Reutiliza IRelatorioService para obter os dados (sem duplicar queries)
///   - ClosedXML para .xlsx (puro .NET, sem Excel instalado)
///   - QuestPDF para .pdf (fluent API, sem iTextSharp/licenças complexas)
/// </summary>
public class ExportacaoService : IExportacaoService
{
    private readonly IRelatorioService _relatorioService;
    private readonly ILogger<ExportacaoService> _logger;

    public ExportacaoService(IRelatorioService relatorioService, ILogger<ExportacaoService> logger)
    {
        _relatorioService = relatorioService;
        _logger = logger;

        // QuestPDF requer licença declarada (Community é gratuita para uso comercial)
        QuestPDF.Settings.License = LicenseType.Community;
    }

    // =========================================================================
    // EXCEL — ClosedXML
    // =========================================================================

    /// <inheritdoc/>
    public async Task<byte[]> ExportarExcelAsync(DateTime inicio, DateTime fim)
    {
        _logger.LogInformation("[Exportacao] Gerando Excel de {Inicio} a {Fim}", inicio, fim);

        // Busca todos os dados reutilizando o service existente
        var financeiro = await _relatorioService.GetRelatorioFinanceiroAsync(inicio, fim);
        var produtos = await _relatorioService.GetProdutosMaisVendidosAsync(inicio, fim, 20);
        var historico = await _relatorioService.GetHistoricoVendasAsync(inicio, fim);
        var topClientes = await _relatorioService.GetTopClientesAsync(inicio, fim, 5);

        using var workbook = new XLWorkbook();

        // aba 1: Resumo Financeiro
        CriarAbaFinanceiro(workbook, financeiro, inicio, fim);

        // aba 2: Produtos Mais Vendidos
        CriarAbaProdutos(workbook, produtos);

        // aba 3: Histórico de Vendas
        CriarAbaVendas(workbook, historico);

        // aba 4: Top Clientes
        CriarAbaTopClientes(workbook, topClientes);

        // Retorna como array de bytes para streaming via HTTP
        using var stream = new MemoryStream();
        workbook.SaveAs(stream);
        return stream.ToArray();
    }

    // -------------------------------------------------------------------------
    // Helpers de abas Excel
    // -------------------------------------------------------------------------

    private static void CriarAbaFinanceiro(XLWorkbook wb, RelatorioFinanceiroDto dto, DateTime inicio, DateTime fim)
    {
        var ws = wb.Worksheets.Add("Resumo Financeiro");

        // Cabeçalho do relatório
        ws.Cell(1, 1).Value = "MaxiMassas — Resumo Financeiro";
        ws.Cell(1, 1).Style.Font.Bold = true;
        ws.Cell(1, 1).Style.Font.FontSize = 14;
        ws.Cell(2, 1).Value = $"Período: {inicio:dd/MM/yyyy} até {fim:dd/MM/yyyy}";
        ws.Cell(2, 1).Style.Font.Italic = true;

        // Dados em par chave:valor
        var linhas = new[]
        {
            ("Total Faturado", dto.TotalFaturado.ToString("C2")),
            ("Total de Custo", dto.TotalCusto.ToString("C2")),
            ("Lucro Bruto", dto.LucroBruto.ToString("C2")),
            ("Ticket Médio", dto.TicketMedio.ToString("C2")),
            ("Total de Vendas", dto.TotalVendas.ToString()),
            ("Vendas Pagas", dto.VendasPagas.ToString()),
            ("Vendas Pendentes", dto.VendasPendentes.ToString()),
            ("Vendas Canceladas", dto.VendasCanceladas.ToString()),
        };

        for (int i = 0; i < linhas.Length; i++)
        {
            ws.Cell(4 + i, 1).Value = linhas[i].Item1;
            ws.Cell(4 + i, 2).Value = linhas[i].Item2;
            ws.Cell(4 + i, 1).Style.Font.Bold = true;
        }

        ws.Columns().AdjustToContents();
    }

    private static void CriarAbaProdutos(XLWorkbook wb, IEnumerable<ProdutoMaisVendidoDto> produtos)
    {
        var ws = wb.Worksheets.Add("Produtos Mais Vendidos");

        // Cabeçalhos da tabela
        ws.Cell(1, 1).Value = "Posição";
        ws.Cell(1, 2).Value = "Produto";
        ws.Cell(1, 3).Value = "Qtd Vendida";
        ws.Cell(1, 4).Value = "Total Faturado";

        var headerRow = ws.Row(1);
        headerRow.Style.Font.Bold = true;
        headerRow.Style.Fill.BackgroundColor = XLColor.Orange;
        headerRow.Style.Font.FontColor = XLColor.White;

        int row = 2;
        int pos = 1;
        foreach (var p in produtos)
        {
            ws.Cell(row, 1).Value = pos++;
            ws.Cell(row, 2).Value = p.NomeProduto;
            ws.Cell(row, 3).Value = p.QuantidadeVendida;
            ws.Cell(row, 4).Value = p.TotalFaturado;
            ws.Cell(row, 4).Style.NumberFormat.Format = "R$ #,##0.00";
            row++;
        }

        ws.Columns().AdjustToContents();
    }

    private static void CriarAbaVendas(XLWorkbook wb, IEnumerable<HistoricoVendaDto> vendas)
    {
        var ws = wb.Worksheets.Add("Histórico de Vendas");

        ws.Cell(1, 1).Value = "ID";
        ws.Cell(1, 2).Value = "Data";
        ws.Cell(1, 3).Value = "Cliente";
        ws.Cell(1, 4).Value = "Valor Total";
        ws.Cell(1, 5).Value = "Status";
        ws.Cell(1, 6).Value = "Origem";

        var headerRow = ws.Row(1);
        headerRow.Style.Font.Bold = true;
        headerRow.Style.Fill.BackgroundColor = XLColor.DarkOrange;
        headerRow.Style.Font.FontColor = XLColor.White;

        int row = 2;
        foreach (var v in vendas)
        {
            ws.Cell(row, 1).Value = v.VendaId;
            ws.Cell(row, 2).Value = v.Data.ToString("dd/MM/yyyy HH:mm");
            ws.Cell(row, 3).Value = v.NomeCliente;
            ws.Cell(row, 4).Value = v.ValorTotal;
            ws.Cell(row, 4).Style.NumberFormat.Format = "R$ #,##0.00";
            ws.Cell(row, 5).Value = v.StatusPagamento;
            ws.Cell(row, 6).Value = v.Origem;
            row++;
        }

        ws.Columns().AdjustToContents();
    }

    private static void CriarAbaTopClientes(XLWorkbook wb, IEnumerable<TopClienteDto> clientes)
    {
        var ws = wb.Worksheets.Add("Top Clientes");

        ws.Cell(1, 1).Value = "Posição";
        ws.Cell(1, 2).Value = "Cliente";
        ws.Cell(1, 3).Value = "Total Gasto";
        ws.Cell(1, 4).Value = "Qtd de Compras";

        var headerRow = ws.Row(1);
        headerRow.Style.Font.Bold = true;
        headerRow.Style.Fill.BackgroundColor = XLColor.SteelBlue;
        headerRow.Style.Font.FontColor = XLColor.White;

        int row = 2;
        foreach (var c in clientes)
        {
            ws.Cell(row, 1).Value = c.Posicao;
            ws.Cell(row, 2).Value = c.NomeCliente;
            ws.Cell(row, 3).Value = c.TotalGasto;
            ws.Cell(row, 3).Style.NumberFormat.Format = "R$ #,##0.00";
            ws.Cell(row, 4).Value = c.QuantidadeCompras;
            row++;
        }

        ws.Columns().AdjustToContents();
    }

    // =========================================================================
    // PDF — QuestPDF
    // =========================================================================

    /// <inheritdoc/>
    public async Task<byte[]> ExportarPdfAsync(DateTime inicio, DateTime fim)
    {
        _logger.LogInformation("[Exportacao] Gerando PDF de {Inicio} a {Fim}", inicio, fim);

        var financeiro = await _relatorioService.GetRelatorioFinanceiroAsync(inicio, fim);
        var produtos = (await _relatorioService.GetProdutosMaisVendidosAsync(inicio, fim, 10)).ToList();
        var topClientes = (await _relatorioService.GetTopClientesAsync(inicio, fim, 5)).ToList();

        // QuestPDF usa Fluent API para definir o layout do documento
        var document = Document.Create(container =>
        {
            container.Page(page =>
            {
                page.Size(PageSizes.A4);
                page.Margin(2, Unit.Centimetre);
                page.DefaultTextStyle(x => x.FontSize(10));

                // Cabeçalho do documento
                page.Header().Column(col =>
                {
                    col.Item().Text("MaxiMassas — Relatório Gerencial")
                        .SemiBold().FontSize(16).FontColor(Colors.Orange.Darken2);
                    col.Item().Text($"Período: {inicio:dd/MM/yyyy} a {fim:dd/MM/yyyy}")
                        .FontSize(10).FontColor(Colors.Grey.Darken1);
                    col.Item().LineHorizontal(1).LineColor(Colors.Orange.Medium);
                    col.Item().Height(10);
                });

                page.Content().Column(col =>
                {
                    // Seção 1: Resumo Financeiro
                    col.Item().Text("Resumo Financeiro").Bold().FontSize(12);
                    col.Item().Height(5);

                    col.Item().Table(table =>
                    {
                        table.ColumnsDefinition(c => {
                            c.RelativeColumn(2);
                            c.RelativeColumn(1);
                        });

                        // Linhas da tabela de resumo
                        AdicionarLinhaTabela(table, "Total Faturado", financeiro.TotalFaturado.ToString("C2"), true);
                        AdicionarLinhaTabela(table, "Total de Custo", financeiro.TotalCusto.ToString("C2"), false);
                        AdicionarLinhaTabela(table, "Lucro Bruto", financeiro.LucroBruto.ToString("C2"), true);
                        AdicionarLinhaTabela(table, "Ticket Médio", financeiro.TicketMedio.ToString("C2"), false);
                        AdicionarLinhaTabela(table, "Total de Vendas", financeiro.TotalVendas.ToString(), true);
                        AdicionarLinhaTabela(table, "Vendas Pagas", financeiro.VendasPagas.ToString(), false);
                        AdicionarLinhaTabela(table, "Vendas Pendentes", financeiro.VendasPendentes.ToString(), true);
                        AdicionarLinhaTabela(table, "Vendas Canceladas", financeiro.VendasCanceladas.ToString(), false);
                    });

                    col.Item().Height(15);

                    // Seção 2: Produtos Mais Vendidos
                    col.Item().Text("Top Produtos Mais Vendidos").Bold().FontSize(12);
                    col.Item().Height(5);

                    col.Item().Table(table =>
                    {
                        table.ColumnsDefinition(c => {
                            c.ConstantColumn(30);
                            c.RelativeColumn(3);
                            c.RelativeColumn(1);
                            c.RelativeColumn(2);
                        });

                        // Header da tabela
                        table.Header(header =>
                        {
                            foreach (var h in new[] { "#", "Produto", "Qtd", "Faturado" })
                            {
                                header.Cell()
                                    .Background(Colors.Orange.Medium)
                                    .Padding(4)
                                    .Text(h)
                                    .Bold()
                                    .FontColor(Colors.White);
                            }
                        });

                        int pos = 1;
                        foreach (var p in produtos)
                        {
                            var bg = pos % 2 == 0 ? Colors.Grey.Lighten4 : Colors.White;
                            table.Cell().Background(bg).Padding(4).Text(pos.ToString());
                            table.Cell().Background(bg).Padding(4).Text(p.NomeProduto);
                            table.Cell().Background(bg).Padding(4).Text(p.QuantidadeVendida.ToString());
                            table.Cell().Background(bg).Padding(4).Text(p.TotalFaturado.ToString("C2"));
                            pos++;
                        }
                    });

                    col.Item().Height(15);

                    // Seção 3: Top Clientes
                    col.Item().Text("Top 5 Clientes por Valor Gasto").Bold().FontSize(12);
                    col.Item().Height(5);

                    col.Item().Table(table =>
                    {
                        table.ColumnsDefinition(c => {
                            c.ConstantColumn(30);
                            c.RelativeColumn(3);
                            c.RelativeColumn(2);
                            c.RelativeColumn(1);
                        });

                        table.Header(header =>
                        {
                            foreach (var h in new[] { "#", "Cliente", "Total Gasto", "Compras" })
                            {
                                header.Cell()
                                    .Background(Colors.Blue.Medium)
                                    .Padding(4)
                                    .Text(h)
                                    .Bold()
                                    .FontColor(Colors.White);
                            }
                        }); ;

                        foreach (var c in topClientes)
                        {
                            var bg = c.Posicao % 2 == 0 ? Colors.Grey.Lighten4 : Colors.White;
                            table.Cell().Background(bg).Padding(4).Text(c.Posicao.ToString());
                            table.Cell().Background(bg).Padding(4).Text(c.NomeCliente);
                            table.Cell().Background(bg).Padding(4).Text(c.TotalGasto.ToString("C2"));
                            table.Cell().Background(bg).Padding(4).Text(c.QuantidadeCompras.ToString());
                        }
                    });
                });

                // Rodapé com paginação
                page.Footer().AlignCenter()
                    .Text(x => {
                        x.Span("MaxiMassas — Gerado em: ");
                        x.Span(DateTime.Now.ToString("dd/MM/yyyy HH:mm"));
                        x.Span(" | Página ");
                        x.CurrentPageNumber();
                        x.Span(" de ");
                        x.TotalPages();
                    });
            });
        });

        return document.GeneratePdf();
    }

    // Helper: adiciona linha zebrada na tabela do PDF
    private static void AdicionarLinhaTabela(TableDescriptor table, string label, string valor, bool par)
    {
        var bg = par ? Colors.Grey.Lighten4 : Colors.White;
        table.Cell().Background(bg).Padding(5).Text(label).Bold();
        table.Cell().Background(bg).Padding(5).Text(valor);
    }
}
