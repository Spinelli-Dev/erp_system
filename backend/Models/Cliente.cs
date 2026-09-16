// Entidade Cliente — alinhada ao diagrama UML (adicionado CPF e Endereco).
namespace MaxiMassasAPI.Models;

public class Cliente
{
    public int Id { get; set; }

    /// <summary>Nome completo do cliente.</summary>
    public string Nome { get; set; } = string.Empty;

    /// <summary>Telefone/WhatsApp para contato.</summary>
    public string Telefone { get; set; } = string.Empty;

    /// <summary>CPF do cliente (UML: campo obrigatório para identificação).</summary>
    public string? Cpf { get; set; }

    // ── Endereço detalhado (mantido para integração ViaCEP) ──────────────────
    public string CEP { get; set; } = string.Empty;
    public string Logradouro { get; set; } = string.Empty;
    public string Numero { get; set; } = string.Empty;
    public string Bairro { get; set; } = string.Empty;
    public string Cidade { get; set; } = string.Empty;
    public string Estado { get; set; } = string.Empty;
    public string? Complemento { get; set; }

    /// <summary>
    /// Endereço formatado como string única (UML: Endereco : string).
    /// Computed property — não persistida, gerada a partir dos campos detalhados.
    /// </summary>
    public string Endereco => string.IsNullOrEmpty(Logradouro)
        ? string.Empty
        : $"{Logradouro}, {Numero}{(string.IsNullOrEmpty(Complemento) ? "" : $", {Complemento}")} — {Bairro}, {Cidade}/{Estado}";

    public string? Observacao { get; set; }

    public ICollection<Venda> Vendas { get; set; } = new List<Venda>();

    // ── Métodos do diagrama UML (regras de negócio computadas) ───────────────

    /// <summary>
    /// Valor total gasto pelo cliente em vendas concluídas.
    /// UML: valorTotalGasto()
    /// </summary>
    public decimal ValorTotalGasto()
        => Vendas.Where(v => v.Status == StatusVenda.Concluida).Sum(v => v.ValorTotal);
}
