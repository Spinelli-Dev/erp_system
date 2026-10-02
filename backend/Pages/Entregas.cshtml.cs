// Entregas do painel: lista de vendas com entrega (retiradas ficam de fora), montada no servidor,
// e o modal "Pedido mínimo e taxa de entrega", gravado pelo ConfiguracaoEntregaService (só Administrador).
using MaxiMassasAPI.DTOs.Request;
using MaxiMassasAPI.DTOs.Response;
using MaxiMassasAPI.Models;
using MaxiMassasAPI.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace MaxiMassasAPI.Pages;

/// <summary>Endereço exibido de uma entrega: o do pedido (app/PDV) ou, sem ele, o do cadastro do cliente.</summary>
public record EnderecoEntrega(string Rua, string Numero, string Bairro, string Complemento, string Cidade);

public record LinhaEntrega(VendaResponse Venda, EnderecoEntrega Endereco);

public class EntregasModel : PageModel
{
    private readonly IVendaService _vendas;
    private readonly IClienteService _clientes;
    private readonly IConfiguracaoEntregaService _config;
    private readonly ILogger<EntregasModel> _logger;

    public EntregasModel(IVendaService vendas, IClienteService clientes, IConfiguracaoEntregaService config,
        ILogger<EntregasModel> logger)
    {
        _vendas = vendas;
        _clientes = clientes;
        _config = config;
        _logger = logger;
    }

    public IReadOnlyList<LinhaEntrega> Linhas { get; private set; } = Array.Empty<LinhaEntrega>();
    public IReadOnlyList<int> Anos { get; private set; } = Array.Empty<int>();
    public ConfiguracaoEntregaResponse Taxa { get; private set; } = new();
    public bool PodeAlterarTaxa => User.IsInRole(nameof(TipoUsuario.Administrador));

    /// <summary>Valores digitados no modal da taxa e o erro, quando o envio é recusado.</summary>
    public string? TaxaDigitada { get; private set; }
    public string? MinimoDigitado { get; private set; }
    public string? ErroTaxa { get; private set; }

    public async Task OnGetAsync() => await CarregarAsync();

    public async Task<IActionResult> OnPostTaxaAsync(string? taxaEntrega, string? pedidoMinimo)
    {
        TaxaDigitada = taxaEntrega;
        MinimoDigitado = pedidoMinimo;

        if (!PodeAlterarTaxa) return await ComErroAsync("Somente administradores podem alterar a taxa de entrega.");

        var taxa = PainelFormatos.LerMoeda(taxaEntrega);
        var minimo = PainelFormatos.LerMoeda(pedidoMinimo);
        if (taxa is null or < 0 || minimo is null or < 0)
            return await ComErroAsync("Informe os dois valores em reais, por exemplo R$ 4,99 (use R$ 0,00 para nenhum).");

        await _config.AtualizarAsync(new ConfiguracaoEntregaRequest { TaxaEntrega = taxa.Value, PedidoMinimoEntregaGratis = minimo.Value });
        _logger.LogInformation("[Painel] Taxa de entrega: {Taxa}, grátis a partir de {Minimo}.", taxa, minimo);
        TempData["Mensagem"] = minimo > 0
            ? $"Taxa de entrega: {PainelFormatos.Moeda(taxa.Value)}. Grátis em pedidos a partir de {PainelFormatos.Moeda(minimo.Value)}."
            : $"Taxa de entrega: {PainelFormatos.Moeda(taxa.Value)} em todos os pedidos.";
        return RedirectToPage();
    }

    private async Task<IActionResult> ComErroAsync(string mensagem)
    {
        ErroTaxa = mensagem;
        await CarregarAsync();
        return Page();
    }

    private async Task CarregarAsync()
    {
        var clientes = (await _clientes.GetAllAsync()).ToDictionary(c => c.Id);
        Linhas = (await _vendas.GetAllAsync())
            // Retirada no local não é entrega (pedidos do app com retirada também têm Entrega)
            .Where(v => v.Entrega is not null && v.Entrega.TipoEntrega != TipoEntrega.Retirada)
            .OrderByDescending(v => v.Entrega!.DataEntrega).ThenByDescending(v => v.Data)
            .Select(v => new LinhaEntrega(v, Endereco(v, clientes.GetValueOrDefault(v.ClienteId))))
            .ToList();
        Anos = Linhas.Select(l => l.Venda.Entrega!.DataEntrega.Year).Append(DateTime.Today.Year)
            .Distinct().OrderByDescending(a => a).ToList();
        Taxa = await _config.ObterResponseAsync();
    }

    private static EnderecoEntrega Endereco(VendaResponse v, ClienteResponse? c)
    {
        var e = v.Entrega!;
        return string.IsNullOrEmpty(e.Logradouro)
            ? new EnderecoEntrega(c?.Logradouro ?? "", c?.Numero ?? "", c?.Bairro ?? "", c?.Complemento ?? "", c?.Cidade ?? "")
            : new EnderecoEntrega(e.Logradouro, e.Numero ?? "", e.Bairro ?? "", e.Complemento ?? "", e.Cidade ?? c?.Cidade ?? "");
    }

    /// <summary>Mesmos rótulos de antes: Concluído, Cancelado e o resto "Pendente".</summary>
    public static string RotuloStatus(StatusVenda s) => s switch
    {
        StatusVenda.Concluida => "Concluído",
        StatusVenda.Cancelada => "Cancelado",
        _ => "Pendente"
    };

    public static string Ou(string? texto) => string.IsNullOrWhiteSpace(texto) ? "—" : texto;
}
