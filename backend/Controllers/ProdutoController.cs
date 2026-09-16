using MaxiMassasAPI.DTOs.Common;
using MaxiMassasAPI.DTOs.Request;
using MaxiMassasAPI.DTOs.Response;
using MaxiMassasAPI.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace MaxiMassasAPI.Controllers;

[ApiController][Route("api/[controller]")][Authorize][Produces("application/json")]
public class ProdutoController : ControllerBase
{
    private readonly IProdutoService _svc;
    public ProdutoController(IProdutoService svc) { _svc = svc; }

    [HttpGet] public async Task<IActionResult> GetAll() => Ok(ApiResponse<IEnumerable<ProdutoResponse>>.Ok(await _svc.GetAllAsync()));

    [HttpGet("{id:int}")]
    public async Task<IActionResult> GetById(int id)
    {
        var p = await _svc.GetByIdAsync(id);
        return p is null ? NotFound(ApiResponse.Fail("Produto nao encontrado.")) : Ok(ApiResponse<ProdutoResponse>.Ok(p));
    }

    [HttpPost][Authorize(Roles = "Administrador")]
    public async Task<IActionResult> Create([FromBody] ProdutoRequest req)
    {
        var p = await _svc.CreateAsync(req);
        return CreatedAtAction(nameof(GetById), new { id = p.Id }, ApiResponse<ProdutoResponse>.Ok(p, "Produto criado."));
    }

    [HttpPut("{id:int}")][Authorize(Roles = "Administrador")]
    public async Task<IActionResult> Update(int id, [FromBody] ProdutoUpdateRequest req)
    {
        var p = await _svc.UpdateAsync(id, req);
        return p is null ? NotFound(ApiResponse.Fail("Produto nao encontrado.")) : Ok(ApiResponse<ProdutoResponse>.Ok(p, "Produto atualizado."));
    }

    [HttpDelete("{id:int}")][Authorize(Roles = "Administrador")]
    public async Task<IActionResult> Delete(int id)
    {
        var ok = await _svc.DeleteAsync(id);
        return ok ? Ok(ApiResponse.Ok("Produto removido.")) : NotFound(ApiResponse.Fail("Produto nao encontrado."));
    }
}