namespace MaxiMassasAPI.DTOs.Request;

public class EstoqueRequest
{
    public int ProdutoId { get; set; }
    public int Quantidade { get; set; }
    public int AlertaMinimo { get; set; }
}

public class MovimentacaoEstoqueRequest
{
    public int EstoqueId { get; set; }
    public MaxiMassasAPI.Models.TipoMovimentacao Tipo { get; set; }
    public string Motivo { get; set; } = string.Empty;
    public int Quantidade { get; set; }
}