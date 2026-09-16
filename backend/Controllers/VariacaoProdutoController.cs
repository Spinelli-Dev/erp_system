using MaxiMassasAPI.DTOs.Common;
using MaxiMassasAPI.DTOs.Request;
using MaxiMassasAPI.DTOs.Response;
using MaxiMassasAPI.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace MaxiMassasAPI.Controllers;

[ApiController][Route("api/[controller]")][Authorize][Produces("application/json")]
public class VariacaoProdutoController : ControllerBase
{
    private readonly IVariacaoProdutoService _svc;
    public VariacaoProdutoController(IVariacaoProdutoService svc) { _svc = svc; }

    [HttpGet("produto/{produtoId:int}")]
    public async Task<IActionResult> GetByProduto(int produtoId)
        => Ok(ApiResponse<IEnumerable<VariacaoProdutoResponse>>.Ok(await _svc.GetByProdutoIdAsync(produtoId)));

    [HttpPost][Authorize(Roles = "Administrador")]
    public async Task<IActionResult> Create([FromBody] VariacaoProdutoRequest req)
        => Ok(ApiResponse<VariacaoProdutoResponse>.Ok(await _svc.CreateAsync(req), "Variacao criada."));

    [HttpDelete("{id:int}")][Authorize(Roles = "Administrador")]
    public async Task<IActionResult> Delete(int id)
    {
        var ok = await _svc.DeleteAsync(id);
        return ok ? Ok(ApiResponse.Ok("Variacao removida.")) : NotFound(ApiResponse.Fail("Variacao nao encontrada."));
    }
}