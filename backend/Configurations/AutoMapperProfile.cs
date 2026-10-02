// AutoMapper Profile — atualizado para refletir o diagrama UML.
using AutoMapper;
using MaxiMassasAPI.DTOs.Request;
using MaxiMassasAPI.DTOs.Response;
using MaxiMassasAPI.Models;

namespace MaxiMassasAPI.Configurations;

public class AutoMapperProfile : Profile
{
    public AutoMapperProfile()
    {
        // ── Usuário ───────────────────────────────────────────────────────────
        CreateMap<UsuarioRequest, Usuario>().ForMember(d => d.Senha, o => o.Ignore());
        CreateMap<Usuario, UsuarioResponse>();

        // ── Cliente (+ Cpf) ───────────────────────────────────────────────────
        CreateMap<ClienteRequest, Cliente>();
        CreateMap<ClienteUpdateRequest, Cliente>();
        CreateMap<Cliente, ClienteResponse>()
            .ForMember(d => d.Endereco, o => o.Ignore()); // computed, não mapeado via AutoMapper

        // ── Produto ───────────────────────────────────────────────────────────
        CreateMap<ProdutoRequest, Produto>();
        CreateMap<Produto, ProdutoResponse>()
            .ForMember(d => d.Estoque, o => o.MapFrom(s => s.Estoque));

        // ── Estoque ───────────────────────────────────────────────────────────
        CreateMap<EstoqueRequest, Estoque>();
        CreateMap<Estoque, EstoqueResponse>();
        CreateMap<MovimentacaoEstoque, MovimentacaoEstoqueResponse>();

        // ── Venda (Status → StatusVenda, + Frete, + Observacao) ──────────────
        CreateMap<Venda, VendaResponse>()
            .ForMember(d => d.NomeCliente, o => o.MapFrom(s => s.Cliente != null ? s.Cliente.Nome : string.Empty))
            .ForMember(d => d.NomeUsuario, o => o.MapFrom(s => s.Usuario != null ? s.Usuario.Nome : string.Empty))
            .ForMember(d => d.Itens, o => o.MapFrom(s => s.ItensVenda));

        CreateMap<ItemVenda, ItemVendaResponse>()
            .ForMember(d => d.NomeProduto, o => o.MapFrom(s => s.Produto != null ? s.Produto.NomeCompleto : string.Empty));

        // ── Pagamento (+ StatusPagamento, + DataPagamento) ────────────────────
        CreateMap<Pagamento, PagamentoResponse>();

        // ── Entrega (DataEntrega, Taxa, ValorEntrega) ─────────────────────────
        // Campos renomeados: Data → DataEntrega, TaxaEntrega → Taxa
        CreateMap<Entrega, EntregaResponse>();

        // ── VariacaoProduto (+ Custo) ─────────────────────────────────────────
        CreateMap<VariacaoProdutoRequest, VariacaoProduto>();
        CreateMap<VariacaoProduto, VariacaoProdutoResponse>()
            .ForMember(d => d.NomeProduto, o => o.MapFrom(s => s.Produto != null ? s.Produto.Nome : string.Empty))
            .ForMember(d => d.MargemLucro, o => o.Ignore()); // computed property

        // ── HistoricoPreco (+ MotivoAlteracao, + DataFimVigencia) ─────────────
        CreateMap<HistoricoPreco, HistoricoPrecoResponse>();
    }
}
