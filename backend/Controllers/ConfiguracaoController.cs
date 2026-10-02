// ConfiguracaoController: parâmetros do negócio editados pelos gestores no sistema web.
//
//   GET /api/Configuracao/entrega   [usuario]        taxa de entrega e pedido mínimo para entrega grátis
//   PUT /api/Configuracao/entrega   [Administrador]  altera os dois valores
using MaxiMassasAPI.DTOs.Common;
using MaxiMassasAPI.DTOs.Request;
using MaxiMassasAPI.DTOs.Response;
using MaxiMassasAPI.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace MaxiMassasAPI.Controllers;

[ApiController][Route("api/[controller]")][Authorize][Produces("application/json")]
public class ConfiguracaoController : ControllerBase
{
    private readonly IConfiguracaoEntregaService _svc;
    public ConfiguracaoController(IConfiguracaoEntregaService svc) { _svc = svc; }

    [HttpGet("entrega")]
    public async Task<IActionResult> ObterEntrega()
        => Ok(ApiResponse<ConfiguracaoEntregaResponse>.Ok(await _svc.ObterResponseAsync()));

    [HttpPut("entrega")][Authorize(Roles = "Administrador")]
    public async Task<IActionResult> AtualizarEntrega([FromBody] ConfiguracaoEntregaRequest req)
        => Ok(ApiResponse<ConfiguracaoEntregaResponse>.Ok(await _svc.AtualizarAsync(req), "Taxa de entrega atualizada."));
}
