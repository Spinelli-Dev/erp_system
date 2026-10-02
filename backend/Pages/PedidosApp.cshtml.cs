// Aviso de pedido novo do app: o painel (wwwroot/js/pedidos-app.js) consulta esta página a cada poucos
// segundos e recebe, em JSON, os pedidos do app ainda "Pendentes" (ninguém mudou o status ainda).
// Quando aparece um id novo, o painel toca um som, mostra um aviso e atualiza o contador no menu Vendas.
// O pedido sai da lista assim que alguém o atende (Agendado, Pago, Concluído ou Cancelado).
// Exige o login do painel como qualquer outra página (AuthorizeFolder em Program.cs).
using MaxiMassasAPI.Data;
using MaxiMassasAPI.Models;
using MaxiMassasAPI.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.EntityFrameworkCore;

namespace MaxiMassasAPI.Pages;

[ResponseCache(NoStore = true, Location = ResponseCacheLocation.None)]
public class PedidosAppModel : PageModel
{
    /// <summary>Mesmos status que a tela de Vendas mostra como "Pendente".</summary>
    private static readonly StatusVenda[] Pendentes = { StatusVenda.Nenhum, StatusVenda.Aberta, StatusVenda.EmProcessamento };

    private readonly AppDbContext _db;

    public PedidosAppModel(AppDbContext db) => _db = db;

    public async Task<IActionResult> OnGetAsync()
    {
        var pedidos = await _db.Vendas.AsNoTracking()
            .Where(v => v.Origem == AppClienteService.OrigemApp && Pendentes.Contains(v.Status))
            .OrderByDescending(v => v.Id)
            .Take(20)
            .Select(v => new
            {
                v.Id,
                Cliente = v.Cliente.Nome,
                v.ValorTotal,
                v.Data,
                Entrega = v.Entrega != null && v.Entrega.TipoEntrega == TipoEntrega.Entrega
            })
            .ToListAsync();

        var total = pedidos.Count < 20
            ? pedidos.Count
            : await _db.Vendas.CountAsync(v => v.Origem == AppClienteService.OrigemApp && Pendentes.Contains(v.Status));

        return new JsonResult(new
        {
            total,
            pedidos = pedidos.Select(p => new
            {
                id = p.Id,
                cliente = p.Cliente,
                valor = PainelFormatos.Moeda(p.ValorTotal),
                hora = p.Data.ToString("HH:mm"),
                tipo = p.Entrega ? "Entrega" : "Retirada",
                url = Url.Page("/AlterarVenda", new { id = p.Id })
            })
        });
    }
}
