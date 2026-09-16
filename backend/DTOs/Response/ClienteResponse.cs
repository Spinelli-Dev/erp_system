// Response DTO de Cliente — alinhado ao diagrama UML (+ Cpf, Endereco).
namespace MaxiMassasAPI.DTOs.Response;

public class ClienteResponse
{
    public int Id { get; set; }
    public string Nome { get; set; } = string.Empty;
    public string Telefone { get; set; } = string.Empty;
    /// <summary>CPF formatado. UML: Cpf: string.</summary>
    public string? Cpf { get; set; }
    public string CEP { get; set; } = string.Empty;
    public string Logradouro { get; set; } = string.Empty;
    public string Numero { get; set; } = string.Empty;
    public string Bairro { get; set; } = string.Empty;
    public string Cidade { get; set; } = string.Empty;
    public string Estado { get; set; } = string.Empty;
    public string? Complemento { get; set; }
    public string? Observacao { get; set; }
    /// <summary>UML: Endereco: string — endereço completo formatado.</summary>
    public string Endereco =>
        $"{Logradouro}, {Numero}{(string.IsNullOrEmpty(Complemento) ? "" : $", {Complemento}")} — {Bairro}, {Cidade}/{Estado}";
}
