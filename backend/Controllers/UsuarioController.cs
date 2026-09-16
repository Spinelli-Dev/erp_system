using MaxiMassasAPI.DTOs.Common;
using MaxiMassasAPI.DTOs.Request;
using MaxiMassasAPI.DTOs.Response;
using MaxiMassasAPI.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace MaxiMassasAPI.Controllers;

[ApiController][Route("api/[controller]")][Authorize][Produces("application/json")]
public class UsuarioController : ControllerBase
{
    private readonly IUsuarioService _svc;
    public UsuarioController(IUsuarioService svc) { _svc = svc; }

    [HttpGet][Authorize(Roles = "Administrador")]
    public async Task<IActionResult> GetAll() => Ok(ApiResponse<IEnumerable<UsuarioResponse>>.Ok(await _svc.GetAllAsync()));

    [HttpGet("{id:int}")][Authorize(Roles = "Administrador")]
    public async Task<IActionResult> GetById(int id)
    {
        var u = await _svc.GetByIdAsync(id);
        return u is null ? NotFound(ApiResponse.Fail("Usuario nao encontrado.")) : Ok(ApiResponse<UsuarioResponse>.Ok(u));
    }

    [HttpPost][Authorize(Roles = "Administrador")]
    public async Task<IActionResult> Create([FromBody] UsuarioRequest req)
    {
        var u = await _svc.CreateAsync(req);
        return CreatedAtAction(nameof(GetById), new { id = u.Id }, ApiResponse<UsuarioResponse>.Ok(u, "Usuario criado com sucesso."));
    }

    [HttpPut("{id:int}")][Authorize(Roles = "Administrador")]
    public async Task<IActionResult> Update(int id, [FromBody] UsuarioUpdateRequest req)
    {
        var u = await _svc.UpdateAsync(id, req);
        return u is null ? NotFound(ApiResponse.Fail("Usuario nao encontrado.")) : Ok(ApiResponse<UsuarioResponse>.Ok(u, "Usuario atualizado."));
    }

    [HttpDelete("{id:int}")][Authorize(Roles = "Administrador")]
    public async Task<IActionResult> Delete(int id)
    {
        var ok = await _svc.DeleteAsync(id);
        return ok ? Ok(ApiResponse.Ok("Usuario removido.")) : NotFound(ApiResponse.Fail("Usuario nao encontrado."));
    }
}