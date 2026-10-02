// Endereço salvo pelo cliente no app, para reaproveitar nos próximos pedidos de entrega.
// Regras (garantidas pelo AppClienteService): no máximo um principal por cliente; o
// primeiro salvo vira principal; apagar o principal promove o mais antigo que sobrou.
namespace MaxiMassasAPI.Models;

public class EnderecoCliente
{
    public int Id { get; set; }
    public string Logradouro { get; set; } = string.Empty;
    public string Numero { get; set; } = string.Empty;
    public string? Complemento { get; set; }
    public string Bairro { get; set; } = string.Empty;
    public string? Cep { get; set; }
    public string Cidade { get; set; } = string.Empty;
    /// <summary>UF com 2 letras (ex.: SP).</summary>
    public string Estado { get; set; } = string.Empty;
    public bool Principal { get; set; }

    public int ClienteId { get; set; }
    public Cliente Cliente { get; set; } = null!;
}
