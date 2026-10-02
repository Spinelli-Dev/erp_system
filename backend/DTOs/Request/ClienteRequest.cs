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

    // ── Endereço digitado (opcional) ─────────────────────────────────────────
    // Preenchido: vale o que foi digitado. Vazio: o servidor busca pelo CEP (ViaCEP).
    public string? Logradouro { get; set; }
    public string? Bairro { get; set; }
    public string? Cidade { get; set; }
    /// <summary>UF com 2 letras.</summary>
    public string? Estado { get; set; }
}

/// <summary>Mesmos campos (e mesmas validações) do cadastro.</summary>
public class ClienteUpdateRequest : ClienteRequest
{
}
