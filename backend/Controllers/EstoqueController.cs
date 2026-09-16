using MaxiMassasAPI.DTOs.Common;
using MaxiMassasAPI.DTOs.Request;
using MaxiMassasAPI.DTOs.Response;
using MaxiMassasAPI.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace MaxiMassasAPI.Controllers;

[ApiController][Route("api/[controller]")][Authorize][Produces("application/json")]
public class EstoqueController : ControllerBase
{
    private readonly IEstoqueService _svc;
    public EstoqueController(IEstoqueService svc) { _svc = svc; }

    [HttpGet] public async Task<IActionResult> GetAll() => Ok(ApiResponse<IEnumerable<EstoqueResponse>>.Ok(await _svc.GetAllAsync()));

    [HttpGet("produto/{produtoId:int}")]
    public async Task<IActionResult> GetByProduto(int produtoId)
    {
        var e = await _svc.GetByProdutoIdAsync(produtoId);
        return e is null ? NotFound(ApiResponse.Fail("Estoque nao encontrado.")) : Ok(ApiResponse<EstoqueResponse>.Ok(e));
    }

    [HttpGet("{id:int}/movimentacoes")]
    public async Task<IActionResult> GetComMovimentacoes(int id)
    {
        var e = await _svc.GetComMovimentacoesAsync(id);
        return e is null ? NotFound(ApiResponse.Fail("Estoque nao encontrado.")) : Ok(ApiResponse<EstoqueResponse>.Ok(e));
    }

    [HttpGet("baixos")] public async Task<IActionResult> GetBaixos()
        => Ok(ApiResponse<IEnumerable<EstoqueResponse>>.Ok(await _svc.GetEstoquesBaixosAsync(), "Estoques abaixo do alerta minimo."));

    [HttpPost][Authorize(Roles = "Administrador")]
    public async Task<IActionResult> Create([FromBody] EstoqueRequest req)
        => Ok(ApiResponse<EstoqueResponse>.Ok(await _svc.CreateAsync(req), "Estoque criado."));

    /// <summary>Registra entrada ou saida de estoque.</summary>
    [HttpPost("movimentacao")]
    public async Task<IActionResult> Movimentar([FromBody] MovimentacaoEstoqueRequest req)
    {
        var e = await _svc.RegistrarMovimentacaoAsync(req);
        return e is null ? NotFound(ApiResponse.Fail("Estoque nao encontrado.")) : Ok(ApiResponse<EstoqueResponse>.Ok(e, "Movimentacao registrada."));
    }
}