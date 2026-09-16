// DTOs de Cliente — alinhados ao diagrama UML (adicionado Cpf).
namespace MaxiMassasAPI.DTOs.Request;

public class ClienteRequest
{
    public string Nome { get; set; } = string.Empty;
    public string Telefone { get; set; } = string.Empty;
    /// <summary>CPF do cliente (UML: Cpf: string). Opcional.</summary>
    public string? Cpf { get; set; }
    public string CEP { get; set; } = string.Empty;
    public string Numero { get; set; } = string.Empty;
    public string? Complemento { get; set; }
    public string? Observacao { get; set; }
}

public class ClienteUpdateRequest
{
    public string Nome { get; set; } = string.Empty;
    public string Telefone { get; set; } = string.Empty;
    public string? Cpf { get; set; }
    public string CEP { get; set; } = string.Empty;
    public string Numero { get; set; } = string.Empty;
    public string? Complemento { get; set; }
    public string? Observacao { get; set; }
}
