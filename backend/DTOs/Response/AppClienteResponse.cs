// DTOs de saída dos endpoints do app do cliente (/api/app).
// Expõem só o que o cliente pode ver: sem custo de produto, operador ou dados de outros clientes.
namespace MaxiMassasAPI.DTOs.Response;
using MaxiMassasAPI.Models;

/// <summary>Perfil completo: toda operação de perfil/endereço devolve este objeto já atualizado.</summary>
public class PerfilAppResponse
{
    public int Id { get; set; }
    public string Nome { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string Telefone { get; set; } = string.Empty;
    public List<EnderecoAppResponse> Enderecos { get; set; } = new();
}

public class EnderecoAppResponse
{
    /// <summary>Nulo no endereço de um pedido (não é um endereço salvo).</summary>
    public int? Id { get; set; }
    public string Logradouro { get; set; } = string.Empty;
    public string Numero { get; set; } = string.Empty;
    public string? Complemento { get; set; }
    public string Bairro { get; set; } = string.Empty;
    public string? Cep { get; set; }
    public string Cidade { get; set; } = string.Empty;
    public string Estado { get; set; } = string.Empty;
    public bool Principal { get; set; }
}

/// <summary>Endereço encontrado pelo CEP (ViaCEP), para o app preencher o formulário.</summary>
public class CepAppResponse
{
    public string Cep { get; set; } = string.Empty;
    public string Logradouro { get; set; } = string.Empty;
    public string Bairro { get; set; } = string.Empty;
    public string Cidade { get; set; } = string.Empty;
    public string Estado { get; set; } = string.Empty;
}

public class ProdutoAppResponse
{
    public int Id { get; set; }
    public string Nome { get; set; } = string.Empty;
    public string Descricao { get; set; } = string.Empty;
    public decimal Preco { get; set; }
    public string Categoria { get; set; } = string.Empty;
    public bool Disponivel { get; set; }
    /// <summary>Unidades em estoque: o app não deixa colocar mais do que isso no carrinho.</summary>
    public int Estoque { get; set; }
}

public class PedidoAppResponse
{
    public int Id { get; set; }
    /// <summary>Número exibido ao cliente, ex.: "#000123".</summary>
    public string Numero => $"#{Id:D6}";
    public DateTime Data { get; set; }
    public StatusVenda Status { get; set; }
    public decimal Subtotal { get; set; }
    public decimal TaxaEntrega { get; set; }
    public decimal Total { get; set; }
    public TipoEntrega TipoEntrega { get; set; }
    public EnderecoAppResponse? Endereco { get; set; }
    public string? Horario { get; set; }
    public FormaPagamento FormaPagamento { get; set; }
    public StatusPagamento StatusPagamento { get; set; }
    public string? Observacao { get; set; }
    public List<ItemPedidoAppResponse> Itens { get; set; } = new();
}

public class ItemPedidoAppResponse
{
    public int ProdutoId { get; set; }
    public string Nome { get; set; } = string.Empty;
    public int Quantidade { get; set; }
    public decimal PrecoUnitario { get; set; }
    public decimal Subtotal { get; set; }
}
