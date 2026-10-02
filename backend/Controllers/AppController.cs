// AppController: endpoints do app do cliente (Flutter).
//
// Autenticação própria (ClienteAuth): Basic Auth com e-mail e senha do CLIENTE,
// não do usuário interno. Um cliente só enxerga o cardápio e os próprios dados.
//
//   POST   /api/app/cadastro                    [anônimo]  cria a conta e devolve o perfil
//   POST   /api/app/senha/esqueci               [anônimo]  envia código de 6 dígitos por e-mail (15 min)
//   POST   /api/app/senha/redefinir             [anônimo]  e-mail + código + nova senha
//   GET    /api/app/me                          [cliente]  perfil + endereços (usado como "login")
//   PUT    /api/app/me                          [cliente]  altera nome, e-mail e telefone
//   POST   /api/app/enderecos                   [cliente]  salva um endereço novo
//   PUT    /api/app/enderecos/{id}              [cliente]  altera um endereço salvo
//   DELETE /api/app/enderecos/{id}              [cliente]  apaga um endereço salvo
//   PUT    /api/app/enderecos/{id}/principal    [cliente]  torna um endereço o principal
//   GET    /api/app/entrega                     [anônimo]  taxa de entrega e mínimo para entrega grátis
//   GET    /api/app/cep/{cep}                [anônimo]  rua, bairro, cidade e UF do CEP (preenche o formulário)
//   GET    /api/app/produtos                    [anônimo]  cardápio com preço e disponibilidade
//   POST   /api/app/pedidos                     [cliente]  cria um pedido (vira Venda com Origem = "App")
//   GET    /api/app/pedidos                     [cliente]  histórico do cliente, mais recentes primeiro
//   GET    /api/app/pedidos/{id}                [cliente]  um pedido do cliente (status atualizado)
//
// Toda operação de perfil/endereço devolve o perfil completo já atualizado: quem decide o
// resultado final (ex.: qual endereço vira principal) é o servidor, o app só espelha.
using MaxiMassasAPI.Configurations;
using MaxiMassasAPI.DTOs.Common;
using MaxiMassasAPI.DTOs.Request;
using MaxiMassasAPI.DTOs.Response;
using MaxiMassasAPI.Integrations;
using MaxiMassasAPI.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace MaxiMassasAPI.Controllers;

[ApiController]
[Route("api/app")]
[Authorize(AuthenticationSchemes = ClienteAuthHandler.SchemeName)]
[Produces("application/json")]
public class AppController : ControllerBase
{
    private readonly IAppClienteService _svc;
    private readonly IConfiguracaoEntregaService _configEntrega;
    private readonly IViaCepService _viaCep;
    private readonly IAuthService _auth;

    public AppController(IAppClienteService svc, IConfiguracaoEntregaService configEntrega, IViaCepService viaCep, IAuthService auth)
    {
        _auth = auth;
        _svc = svc;
        _configEntrega = configEntrega;
        _viaCep = viaCep;
    }

    private int ClienteId => int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

    private OkObjectResult Perfil(PerfilAppResponse perfil, string mensagem = "Operacao realizada com sucesso")
        => Ok(ApiResponse<PerfilAppResponse>.Ok(perfil, mensagem));

    // ── Conta e perfil ───────────────────────────────────────────────────────

    /// <summary>Cria a conta do cliente no app. Depois disso ele entra com e-mail e senha.</summary>
    [HttpPost("cadastro")]
    [AllowAnonymous]
    public async Task<IActionResult> Cadastrar([FromBody] CadastroClienteAppRequest req)
    {
        var perfil = await _svc.CadastrarAsync(req);
        return CreatedAtAction(nameof(Me), null, ApiResponse<PerfilAppResponse>.Ok(perfil, "Cadastro realizado."));
    }

    /// <summary>Perfil do cliente autenticado. O app chama este endpoint para validar o login.</summary>
    /// <summary>Esqueci minha senha, passo 1: manda um código de 6 dígitos para o e-mail (se houver conta). Resposta sempre igual.</summary>
    [HttpPost("senha/esqueci")]
    [AllowAnonymous]
    public async Task<IActionResult> EsqueciSenha([FromBody] EsqueciSenhaAppRequest req)
    {
        if (string.IsNullOrWhiteSpace(req.Email))
            return BadRequest(ApiResponse.Fail("Informe o e-mail da sua conta."));
        await _auth.SolicitarCodigoClienteAsync(req.Email);
        return Ok(ApiResponse.Ok("Se houver uma conta com esse e-mail, enviamos um código para criar uma nova senha."));
    }

    /// <summary>Esqueci minha senha, passo 2: confere o código (máx. 5 tentativas) e grava a nova senha.</summary>
    [HttpPost("senha/redefinir")]
    [AllowAnonymous]
    public async Task<IActionResult> RedefinirSenha([FromBody] RedefinirSenhaAppRequest req)
    {
        await _auth.RedefinirSenhaClienteAsync(req);
        return Ok(ApiResponse.Ok("Senha alterada. Entre com a nova senha."));
    }

    [HttpGet("me")]
    public async Task<IActionResult> Me()
    {
        var perfil = await _svc.ObterPerfilAsync(ClienteId);
        return perfil is null ? Unauthorized(ApiResponse.Fail("Cliente nao encontrado.")) : Perfil(perfil);
    }

    /// <summary>Altera os dados de contato. Mudando o e-mail, o próximo login já usa o novo.</summary>
    [HttpPut("me")]
    public async Task<IActionResult> AtualizarPerfil([FromBody] AtualizarPerfilAppRequest req)
        => Perfil(await _svc.AtualizarPerfilAsync(ClienteId, req), "Dados atualizados.");

    // ── Endereços salvos ─────────────────────────────────────────────────────

    [HttpPost("enderecos")]
    public async Task<IActionResult> AdicionarEndereco([FromBody] EnderecoAppRequest req)
        => Perfil(await _svc.AdicionarEnderecoAsync(ClienteId, req), "Endereco salvo.");

    [HttpPut("enderecos/{id:int}")]
    public async Task<IActionResult> AtualizarEndereco(int id, [FromBody] EnderecoAppRequest req)
        => Perfil(await _svc.AtualizarEnderecoAsync(ClienteId, id, req), "Endereco atualizado.");

    [HttpDelete("enderecos/{id:int}")]
    public async Task<IActionResult> RemoverEndereco(int id)
        => Perfil(await _svc.RemoverEnderecoAsync(ClienteId, id), "Endereco removido.");

    [HttpPut("enderecos/{id:int}/principal")]
    public async Task<IActionResult> DefinirPrincipal(int id)
        => Perfil(await _svc.DefinirEnderecoPrincipalAsync(ClienteId, id), "Endereco principal atualizado.");

    // ── Cardápio e entrega ───────────────────────────────────────────────────

    /// <summary>Regra da taxa de entrega definida pelos gestores, para o app mostrar antes do pedido.</summary>
    [HttpGet("entrega")]
    [AllowAnonymous]
    public async Task<IActionResult> Entrega()
        => Ok(ApiResponse<ConfiguracaoEntregaResponse>.Ok(await _configEntrega.ObterResponseAsync()));

    /// <summary>Consulta o CEP no ViaCEP para o app preencher rua, bairro, cidade e estado.</summary>
    [HttpGet("cep/{cep}")]
    [AllowAnonymous]
    public async Task<IActionResult> BuscarCep(string cep)
    {
        var e = await _viaCep.BuscarEnderecoPorCepAsync(cep);
        return e is null
            ? NotFound(ApiResponse.Fail("CEP nao encontrado. Confira os numeros ou preencha o endereco manualmente."))
            : Ok(ApiResponse<CepAppResponse>.Ok(new CepAppResponse
            {
                Cep = e.CEP, Logradouro = e.Logradouro, Bairro = e.Bairro, Cidade = e.Localidade, Estado = e.UF
            }));
    }

    [HttpGet("produtos")]
    [AllowAnonymous]
    public async Task<IActionResult> Produtos()
        => Ok(ApiResponse<IEnumerable<ProdutoAppResponse>>.Ok(await _svc.ListarProdutosAsync()));

    // ── Pedidos ──────────────────────────────────────────────────────────────

    [HttpPost("pedidos")]
    public async Task<IActionResult> CriarPedido([FromBody] PedidoAppRequest req)
    {
        var pedido = await _svc.CriarPedidoAsync(ClienteId, req);
        return CreatedAtAction(nameof(ObterPedido), new { id = pedido.Id },
            ApiResponse<PedidoAppResponse>.Ok(pedido, "Pedido recebido."));
    }

    [HttpGet("pedidos")]
    public async Task<IActionResult> ListarPedidos()
        => Ok(ApiResponse<IEnumerable<PedidoAppResponse>>.Ok(await _svc.ListarPedidosAsync(ClienteId)));

    [HttpGet("pedidos/{id:int}")]
    public async Task<IActionResult> ObterPedido(int id)
    {
        var pedido = await _svc.ObterPedidoAsync(ClienteId, id);
        return pedido is null ? NotFound(ApiResponse.Fail("Pedido nao encontrado.")) : Ok(ApiResponse<PedidoAppResponse>.Ok(pedido));
    }
}
