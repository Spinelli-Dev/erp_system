// DTOs de entrada dos endpoints do app do cliente (/api/app).
// Mais enxutos que VendaRequest: o cliente não escolhe preço, desconto, taxa nem status —
// tudo isso é decidido pelo servidor.
namespace MaxiMassasAPI.DTOs.Request;
using MaxiMassasAPI.Models;

public class CadastroClienteAppRequest
{
    public string Nome { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string Telefone { get; set; } = string.Empty;
    public string Senha { get; set; } = string.Empty;
}

public class AtualizarPerfilAppRequest
{
    public string Nome { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string Telefone { get; set; } = string.Empty;
}

/// <summary>Endereço de um pedido de entrega, ou de um endereço salvo no perfil.</summary>
public class EnderecoAppRequest
{
    public string Logradouro { get; set; } = string.Empty;
    public string Numero { get; set; } = string.Empty;
    public string? Complemento { get; set; }
    public string Bairro { get; set; } = string.Empty;
    public string? Cep { get; set; }
    public string Cidade { get; set; } = string.Empty;
    /// <summary>UF com 2 letras (ex.: SP).</summary>
    public string Estado { get; set; } = string.Empty;
    /// <summary>Só nos endereços salvos: torna este o principal (desmarca o anterior).</summary>
    public bool Principal { get; set; }
}

public class PedidoAppRequest
{
    public List<ItemVendaRequest> Itens { get; set; } = new();
    public TipoEntrega TipoEntrega { get; set; }
    /// <summary>Obrigatório quando TipoEntrega = Entrega.</summary>
    public EnderecoAppRequest? Endereco { get; set; }
    /// <summary>Horário desejado (ex.: "19:30" ou "Assim que possível").</summary>
    public string? Horario { get; set; }
    public FormaPagamento FormaPagamento { get; set; }
    public string? Observacao { get; set; }
}
