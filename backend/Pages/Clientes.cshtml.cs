// Clientes do painel: a lista é montada no servidor e o modal "+ NOVO"/editar grava pelo ClienteService
// (o mesmo da API), com as mesmas validações do POST/PUT /api/Cliente.
using FluentValidation;
using System.ComponentModel.DataAnnotations;
using MaxiMassasAPI.DTOs.Request;
using MaxiMassasAPI.DTOs.Response;
using MaxiMassasAPI.Models;
using MaxiMassasAPI.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace MaxiMassasAPI.Pages;

public class ClienteForm
{
    /// <summary>0 = cliente novo.</summary>
    public int Id { get; set; }
    [DisplayFormat(ConvertEmptyStringToNull = false)] public string Nome { get; set; } = string.Empty;
    [DisplayFormat(ConvertEmptyStringToNull = false)] public string Telefone { get; set; } = string.Empty;
    [DisplayFormat(ConvertEmptyStringToNull = false)] public string Cep { get; set; } = string.Empty;
    public string? Rua { get; set; }
    [DisplayFormat(ConvertEmptyStringToNull = false)] public string Numero { get; set; } = string.Empty;
    public string? Bairro { get; set; }
    public string? Cidade { get; set; }
    public string? Uf { get; set; }
    public string? Complemento { get; set; }
    public string? Observacao { get; set; }
}

public record ClienteLinha(ClienteResponse Cliente, int Compras, decimal TotalGasto);

public class ClientesModel : PageModel
{
    private readonly IClienteService _clientes;
    private readonly IVendaService _vendas;
    private readonly IValidator<ClienteRequest> _validador;
    private readonly ILogger<ClientesModel> _logger;

    public ClientesModel(IClienteService clientes, IVendaService vendas, IValidator<ClienteRequest> validador,
        ILogger<ClientesModel> logger)
    {
        _clientes = clientes;
        _vendas = vendas;
        _validador = validador;
        _logger = logger;
    }

    public IReadOnlyList<ClienteLinha> Linhas { get; private set; } = Array.Empty<ClienteLinha>();

    [BindProperty] public ClienteForm Cliente { get; set; } = new();

    /// <summary>Erros do último envio — a página reabre o modal com o que foi digitado.</summary>
    public IReadOnlyList<string> ErrosFormulario { get; private set; } = Array.Empty<string>();

    public async Task OnGetAsync() => await CarregarAsync();

    public async Task<IActionResult> OnPostAsync()
    {
        var request = new ClienteUpdateRequest
        {
            // Campo vazio chega como null (padrão do ASP.NET): vira texto vazio e o validador acusa.
            Nome = (Cliente.Nome ?? string.Empty).Trim(),
            Telefone = (Cliente.Telefone ?? string.Empty).Trim(),
            CEP = (Cliente.Cep ?? string.Empty).Trim(),
            Numero = (Cliente.Numero ?? string.Empty).Trim(),
            Complemento = Vazio(Cliente.Complemento),
            Observacao = Vazio(Cliente.Observacao),
            Logradouro = Vazio(Cliente.Rua),
            Bairro = Vazio(Cliente.Bairro),
            Cidade = Vazio(Cliente.Cidade),
            Estado = Vazio(Cliente.Uf)?.ToUpper()
        };

        var validacao = await _validador.ValidateAsync(request);
        if (!validacao.IsValid)
        {
            ErrosFormulario = validacao.Errors.Select(e => TraduzirErro(e.ErrorMessage)).Distinct().ToList();
            await CarregarAsync();
            return Page();
        }

        if (Cliente.Id == 0)
        {
            var criado = await _clientes.CreateAsync(request);
            TempData["Mensagem"] = $"Cliente {criado.Nome} cadastrado.";
            _logger.LogInformation("[Painel] Cliente {Id} cadastrado.", criado.Id);
        }
        else
        {
            var atualizado = await _clientes.UpdateAsync(Cliente.Id, request);
            TempData["Mensagem"] = atualizado is null
                ? "Este cliente não existe mais."
                : $"Cadastro de {atualizado.Nome} atualizado.";
        }
        return RedirectToPage();
    }

    private async Task CarregarAsync()
    {
        var clientes = await _clientes.GetAllAsync();
        // Compras e total gasto: só vendas que valeram (canceladas não contam).
        var porCliente = (await _vendas.GetAllAsync())
            .Where(v => v.Status != StatusVenda.Cancelada)
            .GroupBy(v => v.ClienteId)
            .ToDictionary(g => g.Key, g => (Compras: g.Count(), Total: g.Sum(v => v.ValorTotal)));

        Linhas = clientes
            .OrderBy(c => c.Nome)
            .Select(c => porCliente.TryGetValue(c.Id, out var a)
                ? new ClienteLinha(c, a.Compras, a.Total)
                : new ClienteLinha(c, 0, 0))
            .ToList();
    }

    private static string? Vazio(string? s) => string.IsNullOrWhiteSpace(s) ? null : s.Trim();

    /// <summary>As mensagens do validador (compartilhado com a API) estão sem acento; aqui ficam legíveis.</summary>
    private static string TraduzirErro(string mensagem) => mensagem
        .Replace("e obrigatorio", "é obrigatório")
        .Replace("invalido", "inválido")
        .Replace("Numero", "Número")
        .Replace("numero", "número")
        .Replace("digitos", "dígitos");
}
