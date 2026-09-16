using MaxiMassasAPI.DTOs.Common;
using MaxiMassasAPI.DTOs.Request;
using MaxiMassasAPI.DTOs.Response;
using MaxiMassasAPI.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace MaxiMassasAPI.Controllers;

[ApiController][Route("api/[controller]")][Authorize][Produces("application/json")]
public class VendaController : ControllerBase
{
    private readonly IVendaService _svc;
    public VendaController(IVendaService svc) { _svc = svc; }

    [HttpGet] public async Task<IActionResult> GetAll() => Ok(ApiResponse<IEnumerable<VendaResponse>>.Ok(await _svc.GetAllAsync()));

    [HttpGet("{id:int}")]
    public async Task<IActionResult> GetById(int id)
    {
        var v = await _svc.GetByIdAsync(id);
        return v is null ? NotFound(ApiResponse.Fail("Venda nao encontrada.")) : Ok(ApiResponse<VendaResponse>.Ok(v));
    }

    /// <summary>Cria venda. O usuario autenticado e vinculado automaticamente.</summary>
    [HttpPost]
    public async Task<IActionResult> Create([FromBody] VendaRequest req)
    {
        var uidStr = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (!int.TryParse(uidStr, out var uid)) return Unauthorized(ApiResponse.Fail("Usuario nao identificado."));
        var v = await _svc.CreateAsync(req, uid);
        return CreatedAtAction(nameof(GetById), new { id = v.Id }, ApiResponse<VendaResponse>.Ok(v, "Venda registrada."));
    }

    [HttpPut("{id:int}")]
    public async Task<IActionResult> Update(int id, [FromBody] VendaUpdateRequest req)
    {
        var v = await _svc.UpdateAsync(id, req);
        return v is null ? NotFound(ApiResponse.Fail("Venda nao encontrada.")) : Ok(ApiResponse<VendaResponse>.Ok(v, "Venda atualizada."));
    }

    [HttpDelete("{id:int}")][Authorize(Roles = "Administrador")]
    public async Task<IActionResult> Delete(int id)
    {
        var ok = await _svc.DeleteAsync(id);
        return ok ? Ok(ApiResponse.Ok("Venda removida.")) : NotFound(ApiResponse.Fail("Venda nao encontrada."));
    }
}