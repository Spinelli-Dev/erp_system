// AppClienteService — regras dos endpoints usados pelo app do cliente (/api/app).
//
// Os pedidos do app viram Vendas comuns (Origem = "App", sem operador) criadas pelo
// mesmo VendaService do balcão: assim validam e baixam estoque do mesmo jeito e
// aparecem automaticamente na tela de vendas dos gestores. A taxa de entrega vem da
// ConfiguracaoEntrega, definida pelos gestores no sistema web.
using MaxiMassasAPI.DTOs.Request;
using MaxiMassasAPI.DTOs.Response;
using MaxiMassasAPI.Models;
using MaxiMassasAPI.Repositories;

namespace MaxiMassasAPI.Services;

public interface IAppClienteService
{
    Task<PerfilAppResponse> CadastrarAsync(CadastroClienteAppRequest request);
    Task<PerfilAppResponse?> ObterPerfilAsync(int clienteId);
    Task<PerfilAppResponse> AtualizarPerfilAsync(int clienteId, AtualizarPerfilAppRequest request);

    /// <summary>Endereço sem id = novo; o primeiro salvo vira principal.</summary>
    Task<PerfilAppResponse> AdicionarEnderecoAsync(int clienteId, EnderecoAppRequest request);
    Task<PerfilAppResponse> AtualizarEnderecoAsync(int clienteId, int enderecoId, EnderecoAppRequest request);
    Task<PerfilAppResponse> RemoverEnderecoAsync(int clienteId, int enderecoId);
    Task<PerfilAppResponse> DefinirEnderecoPrincipalAsync(int clienteId, int enderecoId);

    Task<IEnumerable<ProdutoAppResponse>> ListarProdutosAsync();
    Task<PedidoAppResponse> CriarPedidoAsync(int clienteId, PedidoAppRequest request);
    Task<IEnumerable<PedidoAppResponse>> ListarPedidosAsync(int clienteId);
    Task<PedidoAppResponse?> ObterPedidoAsync(int clienteId, int pedidoId);
}

public class AppClienteService : IAppClienteService
{
    public const string OrigemApp = "App";

    private readonly IClienteRepository _clienteRepo;
    private readonly IProdutoRepository _produtoRepo;
    private readonly IVendaRepository _vendaRepo;
    private readonly IVendaService _vendaService;
    private readonly IConfiguracaoEntregaService _configEntrega;
    private readonly ILogger<AppClienteService> _logger;

    public AppClienteService(
        IClienteRepository clienteRepo,
        IProdutoRepository produtoRepo,
        IVendaRepository vendaRepo,
        IVendaService vendaService,
        IConfiguracaoEntregaService configEntrega,
        ILogger<AppClienteService> logger)
    {
        _clienteRepo = clienteRepo;
        _produtoRepo = produtoRepo;
        _vendaRepo = vendaRepo;
        _vendaService = vendaService;
        _configEntrega = configEntrega;
        _logger = logger;
    }

    // ── Conta e perfil ───────────────────────────────────────────────────────

    public async Task<PerfilAppResponse> CadastrarAsync(CadastroClienteAppRequest request)
    {
        var email = NormalizarEmail(request.Email);
        if (await _clienteRepo.GetByEmailAsync(email) is not null)
            throw new InvalidOperationException("Este e-mail ja esta cadastrado.");

        // Endereço do cadastro fica em branco: ele vem dos endereços salvos no app.
        var cliente = new Cliente
        {
            Nome = request.Nome.Trim(),
            Email = email,
            Telefone = request.Telefone.Trim(),
            SenhaHash = BCrypt.Net.BCrypt.HashPassword(request.Senha)
        };
        await _clienteRepo.AddAsync(cliente);
        await _clienteRepo.SaveChangesAsync();

        _logger.LogInformation("[App] Cliente cadastrado: {ClienteId}", cliente.Id);
        return ParaPerfil(cliente);
    }

    public async Task<PerfilAppResponse?> ObterPerfilAsync(int clienteId)
    {
        var cliente = await _clienteRepo.GetComEnderecosAsync(clienteId);
        return cliente is null ? null : ParaPerfil(cliente);
    }

    public async Task<PerfilAppResponse> AtualizarPerfilAsync(int clienteId, AtualizarPerfilAppRequest request)
    {
        var cliente = await CarregarAsync(clienteId);
        var email = NormalizarEmail(request.Email);

        if (email != cliente.Email)
        {
            var dono = await _clienteRepo.GetByEmailAsync(email);
            if (dono is not null && dono.Id != clienteId)
                throw new InvalidOperationException("Este e-mail ja esta em uso por outra conta.");
        }

        cliente.Nome = request.Nome.Trim();
        cliente.Email = email;
        cliente.Telefone = request.Telefone.Trim();
        await _clienteRepo.SaveChangesAsync();
        return ParaPerfil(cliente);
    }

    // ── Endereços salvos ─────────────────────────────────────────────────────

    public async Task<PerfilAppResponse> AdicionarEnderecoAsync(int clienteId, EnderecoAppRequest request)
    {
        var cliente = await CarregarAsync(clienteId);
        var endereco = new EnderecoCliente();
        Preencher(endereco, request);
        cliente.Enderecos.Add(endereco);

        if (request.Principal || cliente.Enderecos.Count == 1) MarcarPrincipal(cliente, endereco);
        await _clienteRepo.SaveChangesAsync();
        return ParaPerfil(cliente);
    }

    public async Task<PerfilAppResponse> AtualizarEnderecoAsync(int clienteId, int enderecoId, EnderecoAppRequest request)
    {
        var cliente = await CarregarAsync(clienteId);
        var endereco = EnderecoDo(cliente, enderecoId);
        Preencher(endereco, request);

        // O principal não é "desmarcado" direto: só trocando por outro.
        if (request.Principal || endereco.Principal) MarcarPrincipal(cliente, endereco);
        await _clienteRepo.SaveChangesAsync();
        return ParaPerfil(cliente);
    }

    public async Task<PerfilAppResponse> RemoverEnderecoAsync(int clienteId, int enderecoId)
    {
        var cliente = await CarregarAsync(clienteId);
        var endereco = EnderecoDo(cliente, enderecoId);
        cliente.Enderecos.Remove(endereco);

        var proximo = cliente.Enderecos.OrderBy(e => e.Id).FirstOrDefault();
        if (endereco.Principal && proximo is not null) MarcarPrincipal(cliente, proximo);
        await _clienteRepo.SaveChangesAsync();
        return ParaPerfil(cliente);
    }

    public async Task<PerfilAppResponse> DefinirEnderecoPrincipalAsync(int clienteId, int enderecoId)
    {
        var cliente = await CarregarAsync(clienteId);
        MarcarPrincipal(cliente, EnderecoDo(cliente, enderecoId));
        await _clienteRepo.SaveChangesAsync();
        return ParaPerfil(cliente);
    }

    /// <summary>
    /// Deixa só [principal] marcado e copia ele para o endereço do cadastro do cliente,
    /// que é o que a tela de Clientes do sistema web mostra.
    /// </summary>
    private static void MarcarPrincipal(Cliente cliente, EnderecoCliente principal)
    {
        foreach (var e in cliente.Enderecos) e.Principal = ReferenceEquals(e, principal);

        cliente.Logradouro = principal.Logradouro;
        cliente.Numero = principal.Numero;
        cliente.Complemento = principal.Complemento;
        cliente.Bairro = principal.Bairro;
        var cep = new string((principal.Cep ?? string.Empty).Where(char.IsDigit).ToArray());
        cliente.CEP = cep.Length > 8 ? cep[..8] : cep;
        cliente.Cidade = principal.Cidade;
        cliente.Estado = principal.Estado;
    }

    private static void Preencher(EnderecoCliente destino, EnderecoAppRequest origem)
    {
        destino.Logradouro = origem.Logradouro.Trim();
        destino.Numero = origem.Numero.Trim();
        destino.Complemento = TextoOuNulo(origem.Complemento);
        destino.Bairro = origem.Bairro.Trim();
        destino.Cep = TextoOuNulo(origem.Cep);
        destino.Cidade = origem.Cidade.Trim();
        destino.Estado = origem.Estado.Trim().ToUpper();
    }

    private static EnderecoCliente EnderecoDo(Cliente cliente, int enderecoId)
        => cliente.Enderecos.FirstOrDefault(e => e.Id == enderecoId)
           ?? throw new KeyNotFoundException("Este endereco nao existe mais. Atualize a pagina.");

    private async Task<Cliente> CarregarAsync(int clienteId)
        => await _clienteRepo.GetComEnderecosAsync(clienteId)
           ?? throw new KeyNotFoundException("Cliente nao encontrado.");

    // ── Cardápio ─────────────────────────────────────────────────────────────

    public async Task<IEnumerable<ProdutoAppResponse>> ListarProdutosAsync()
    {
        var produtos = await _produtoRepo.GetAllComEstoqueAsync();
        return produtos
            .OrderBy(p => p.Tipo).ThenBy(p => p.Nome)
            .Select(p => new ProdutoAppResponse
            {
                Id = p.Id,
                // "Pizza Calabresa": sem o sabor, dois sabores do mesmo produto apareceriam iguais no app
                Nome = string.IsNullOrWhiteSpace(p.Sabor) ? p.Nome : $"{p.Nome} {p.Sabor}",
                Descricao = p.Peso > 0 ? $"{p.Peso:0.##} g" : string.Empty,
                Preco = p.PrecoVenda,
                Categoria = CategoriaDoTipo(p.Tipo),
                Disponivel = (p.Estoque?.Quantidade ?? 0) > 0,
                Estoque = Math.Max(0, p.Estoque?.Quantidade ?? 0)
            });
    }

    // ── Pedidos ──────────────────────────────────────────────────────────────

    public async Task<PedidoAppResponse> CriarPedidoAsync(int clienteId, PedidoAppRequest request)
    {
        // Itens repetidos (mesmo produto em duas linhas) viram uma linha só,
        // para a checagem de estoque considerar a quantidade total.
        var itens = request.Itens
            .GroupBy(i => i.ProdutoId)
            .Select(g => new ItemVendaRequest { ProdutoId = g.Key, Quantidade = g.Sum(i => i.Quantidade) })
            .ToList();

        var entrega = request.TipoEntrega == TipoEntrega.Entrega;
        var taxa = entrega ? (await _configEntrega.ObterAsync()).CalcularTaxa(await SubtotalAsync(itens)) : 0m;
        var endereco = entrega ? request.Endereco! : null;

        var venda = new VendaRequest
        {
            ClienteId = clienteId,
            Origem = OrigemApp,
            Observacao = TextoOuNulo(request.Observacao),
            Frete = taxa,
            Itens = itens,
            // Pagamento acontece na entrega/retirada: o gestor marca como pago depois.
            Pagamento = new PagamentoRequest
            {
                FormaPagamento = request.FormaPagamento,
                StatusPagamento = StatusPagamento.Pendente
            },
            Entrega = new EntregaRequest
            {
                TipoEntrega = request.TipoEntrega,
                DataEntrega = DateTime.Now,
                Horario = request.Horario?.Trim() ?? string.Empty,
                ValorEntrega = taxa,
                Logradouro = endereco?.Logradouro.Trim(),
                Numero = endereco?.Numero.Trim(),
                Complemento = TextoOuNulo(endereco?.Complemento),
                Bairro = endereco?.Bairro.Trim(),
                Cep = TextoOuNulo(endereco?.Cep),
                Cidade = endereco?.Cidade.Trim(),
                Estado = endereco?.Estado.Trim().ToUpper()
            }
        };

        var criada = await _vendaService.CreateAsync(venda, usuarioId: null);
        _logger.LogInformation("[App] Pedido #{VendaId} criado pelo cliente {ClienteId}", criada.Id, clienteId);

        return (await ObterPedidoAsync(clienteId, criada.Id))!;
    }

    /// <summary>Subtotal pelos preços atuais — base para decidir se a entrega sai grátis.</summary>
    private async Task<decimal> SubtotalAsync(IEnumerable<ItemVendaRequest> itens)
    {
        decimal subtotal = 0;
        foreach (var item in itens)
        {
            var produto = await _produtoRepo.GetByIdAsync(item.ProdutoId)
                ?? throw new KeyNotFoundException($"Produto ID {item.ProdutoId} nao encontrado.");
            subtotal += produto.PrecoVenda * item.Quantidade;
        }
        return subtotal;
    }

    public async Task<IEnumerable<PedidoAppResponse>> ListarPedidosAsync(int clienteId)
        => (await _vendaRepo.GetVendasDoClienteAsync(clienteId)).Select(ParaResponse);

    public async Task<PedidoAppResponse?> ObterPedidoAsync(int clienteId, int pedidoId)
    {
        var venda = await _vendaRepo.GetVendaComDetalhesAsync(pedidoId);
        // Pedido de outro cliente responde como inexistente (não revela que o ID existe).
        return venda is null || venda.ClienteId != clienteId ? null : ParaResponse(venda);
    }

    // ── Mapeamentos ──────────────────────────────────────────────────────────

    private static PerfilAppResponse ParaPerfil(Cliente c) => new()
    {
        Id = c.Id,
        Nome = c.Nome,
        Email = c.Email ?? string.Empty,
        Telefone = c.Telefone,
        Enderecos = c.Enderecos.OrderBy(e => e.Id).Select(e => new EnderecoAppResponse
        {
            Id = e.Id,
            Logradouro = e.Logradouro,
            Numero = e.Numero,
            Complemento = e.Complemento,
            Bairro = e.Bairro,
            Cep = e.Cep,
            Cidade = e.Cidade,
            Estado = e.Estado,
            Principal = e.Principal
        }).ToList()
    };

    private static PedidoAppResponse ParaResponse(Venda v) => new()
    {
        Id = v.Id,
        Data = v.Data,
        Status = v.Status,
        Subtotal = v.ItensVenda.Sum(i => i.Subtotal),
        TaxaEntrega = v.Frete,
        Total = v.ValorTotal,
        TipoEntrega = v.Entrega?.TipoEntrega ?? TipoEntrega.Retirada,
        Endereco = v.Entrega?.Logradouro is null ? null : new EnderecoAppResponse
        {
            Logradouro = v.Entrega.Logradouro,
            Numero = v.Entrega.Numero ?? string.Empty,
            Complemento = v.Entrega.Complemento,
            Bairro = v.Entrega.Bairro ?? string.Empty,
            Cep = v.Entrega.Cep,
            Cidade = v.Entrega.Cidade ?? string.Empty,
            Estado = v.Entrega.Estado ?? string.Empty
        },
        Horario = v.Entrega?.Horario,
        FormaPagamento = v.Pagamento?.FormaPagamento ?? FormaPagamento.Outro,
        StatusPagamento = v.Pagamento?.StatusPagamento ?? StatusPagamento.Pendente,
        Observacao = v.Observacao,
        Itens = v.ItensVenda.Select(i => new ItemPedidoAppResponse
        {
            ProdutoId = i.ProdutoId,
            Nome = i.Produto?.NomeCompleto ?? string.Empty,
            Quantidade = i.Quantidade,
            PrecoUnitario = i.PrecoUnitario,
            Subtotal = i.Subtotal
        }).ToList()
    };

    private static string NormalizarEmail(string email) => email.Trim().ToLower();

    private static string? TextoOuNulo(string? texto) => string.IsNullOrWhiteSpace(texto) ? null : texto.Trim();

    private static string CategoriaDoTipo(TipoProduto tipo) => tipo switch
    {
        TipoProduto.Massa => "Massas",
        TipoProduto.Molho => "Molhos",
        TipoProduto.Recheio => "Recheios",
        TipoProduto.Bebida => "Bebidas",
        _ => "Outros"
    };
}
