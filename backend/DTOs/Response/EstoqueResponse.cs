namespace MaxiMassasAPI.DTOs.Response;

public class EstoqueResponse
{
    public int Id { get; set; }
    public int ProdutoId { get; set; }
    public int Quantidade { get; set; }
    public int AlertaMinimo { get; set; }
    public bool EstoqueBaixo => Quantidade <= AlertaMinimo;
}