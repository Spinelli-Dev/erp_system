// DTOs calculados em tempo real via LINQ - sem tabela fisica de relatorio.
namespace MaxiMassasAPI.DTOs.Relatorio;

public class FaturamentoPorPeriodoDto
{
    public DateTime DataInicio { get; set; }
    public DateTime DataFim { get; set; }
    public decimal TotalFaturado { get; set; }
    public int TotalVendas { get; set; }
}

public class LucroPorPeriodoDto
{
    public DateTime DataInicio { get; set; }
    public DateTime DataFim { get; set; }
    public decimal TotalFaturado { get; set; }
    public decimal TotalCusto { get; set; }
    public decimal LucroBruto { get; set; }
    public decimal MargemLucro { get; set; }
}

public class ProdutoMaisVendidoDto
{
    public int ProdutoId { get; set; }
    public string NomeProduto { get; set; } = string.Empty;
    public int QuantidadeVendida { get; set; }
    public decimal TotalFaturado { get; set; }
}

public class HistoricoVendaDto
{
    public int VendaId { get; set; }
    public DateTime Data { get; set; }
    public string NomeCliente { get; set; } = string.Empty;
    public decimal ValorTotal { get; set; }
    public string StatusPagamento { get; set; } = string.Empty;
    public string Origem { get; set; } = string.Empty;
}

public class RelatorioFinanceiroDto
{
    public decimal TotalFaturado { get; set; }
    public decimal TotalCusto { get; set; }
    public decimal LucroBruto { get; set; }
    public decimal TicketMedio { get; set; }
    public int TotalVendas { get; set; }
    public int VendasPagas { get; set; }
    public int VendasPendentes { get; set; }
    public int VendasCanceladas { get; set; }
}

// RF08 / US15 — Top 5 Clientes por Valor Gasto
/// <summary>
/// DTO para o ranking de clientes com maior volume de compras.
/// Ordenado por TotalGasto descrescente, limitado ao TOP 5.
/// </summary>
public class TopClienteDto
{
    public int ClienteId { get; set; }
    public string NomeCliente { get; set; } = string.Empty;
    public decimal TotalGasto { get; set; }
    public int QuantidadeCompras { get; set; }
    /// <summary>Posição no ranking (1 = maior gastador).</summary>
    public int Posicao { get; set; }
}