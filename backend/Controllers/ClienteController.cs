using MaxiMassasAPI.DTOs.Common;
using MaxiMassasAPI.DTOs.Request;
using MaxiMassasAPI.DTOs.Response;
using MaxiMassasAPI.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace MaxiMassasAPI.Controllers;

[ApiController][Route("api/[controller]")][Authorize][Produces("application/json")]
public class ClienteController : ControllerBase
{
    private readonly IClienteService _svc;
    public ClienteController(IClienteService svc) { _svc = svc; }

    [HttpGet] public async Task<IActionResult> GetAll() => Ok(ApiResponse<IEnumerable<ClienteResponse>>.Ok(await _svc.GetAllAsync()));

    [HttpGet("{id:int}")]
    public async Task<IActionResult> GetById(int id)
    {
        var c = await _svc.GetByIdAsync(id);
        return c is null ? NotFound(ApiResponse.Fail("Cliente nao encontrado.")) : Ok(ApiResponse<ClienteResponse>.Ok(c));
    }

    /// <summary>Cria cliente. Endereco preenchido automaticamente via ViaCEP a partir do CEP.</summary>
    [HttpPost]
    public async Task<IActionResult> Create([FromBody] ClienteRequest req)
    {
        var c = await _svc.CreateAsync(req);
        return CreatedAtAction(nameof(GetById), new { id = c.Id }, ApiResponse<ClienteResponse>.Ok(c, "Cliente criado com sucesso."));
    }

    [HttpPut("{id:int}")]
    public async Task<IActionResult> Update(int id, [FromBody] ClienteUpdateRequest req)
    {
        var c = await _svc.UpdateAsync(id, req);
        return c is null ? NotFound(ApiResponse.Fail("Cliente nao encontrado.")) : Ok(ApiResponse<ClienteResponse>.Ok(c, "Cliente atualizado."));
    }

    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Delete(int id)
    {
        var ok = await _svc.DeleteAsync(id);
        return ok ? Ok(ApiResponse.Ok("Cliente removido.")) : NotFound(ApiResponse.Fail("Cliente nao encontrado."));
    }
}