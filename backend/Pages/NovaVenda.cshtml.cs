// Nova venda (PDV do balcão): grava pelo VendaService — valida e baixa o estoque numa transação.
using MaxiMassasAPI.DTOs.Request;
using MaxiMassasAPI.Models;
using MaxiMassasAPI.Services;
using Microsoft.AspNetCore.Mvc;

namespace MaxiMassasAPI.Pages;

public class NovaVendaModel : PdvPageModel
{
    private readonly ILogger<NovaVendaModel> _logger;

    public NovaVendaModel(IVendaService vendas, IClienteService clientes, IProdutoService produtos,
        IConfiguracaoEntregaService configEntrega, ILogger<NovaVendaModel> logger)
        : base(vendas, clientes, produtos, configEntrega)
    {
        _logger = logger;
    }

    public override string Titulo => "Nova Venda";

    public async Task OnGetAsync() => await CarregarDadosAsync(estado: null, modo: "nova");

    public async Task<IActionResult> OnPostAsync()
    {
        Erro = Validar(out var itens, out var status, out var pagamento, out var dataAgendada);
        if (Erro is null)
        {
            try
            {
                var criada = await Vendas.CreateAsync(await MontarRequestAsync(itens, status, pagamento, dataAgendada), UsuarioId);
                _logger.LogInformation("[Painel] Venda #{VendaId} registrada no PDV.", criada.Id);
                TempData["Mensagem"] = $"Venda #{criada.Id} registrada para {criada.NomeCliente}.";
                return RedirectToPage("/Vendas");
            }
            catch (Exception ex) when (ex is InvalidOperationException or KeyNotFoundException)
            {
                // Ex.: estoque insuficiente (inclusive quando outra venda levou as últimas unidades agora).
                Erro = ex.Message;
            }
        }

        await CarregarDadosAsync(await EstadoDoFormularioAsync(), modo: "nova");
        return Page();
    }

    /// <summary>Confere o formulário; devolve a mensagem do primeiro problema ou null.</summary>
    private string? Validar(out List<ItemForm> itens, out (StatusVenda Venda, StatusPagamento Pagamento) status,
        out FormaPagamento pagamento, out DateTime? dataAgendada)
    {
        itens = LerItens();
        status = default;
        pagamento = default;
        dataAgendada = LerData(Venda.DataAgendada);

        if (Venda.ClienteId <= 0) return "Selecione o cliente da venda.";
        if (itens.Count == 0) return "Adicione pelo menos um produto à comanda.";
        if (Venda.TipoEntrega is not ("Retirada" or "Delivery")) return "Escolha o tipo de entrega (Retirada ou Delivery).";
        if (Venda.TipoEntrega == "Delivery" &&
            (string.IsNullOrWhiteSpace(Venda.Rua) || string.IsNullOrWhiteSpace(Venda.Numero) || string.IsNullOrWhiteSpace(Venda.Bairro)))
            return "Para delivery, preencha rua, número e bairro do endereço de entrega.";
        if (Venda.TipoEntrega == "Delivery" && (Venda.Uf?.Trim().Length ?? 0) > 2) return "UF deve ter 2 letras (ex.: SP).";
        if (string.IsNullOrWhiteSpace(Venda.Plataforma)) return "Escolha a plataforma do pedido.";
        if (!PagamentoPorRotulo.TryGetValue(Venda.Pagamento, out pagamento)) return "Escolha a forma de pagamento.";
        if (!StatusPorRotulo.TryGetValue(Venda.Status, out status)) return "Escolha o status da venda.";
        if (status.Venda == StatusVenda.Cancelada) return "Uma venda nova não pode ser registrada como cancelada.";
        if (!string.IsNullOrWhiteSpace(Venda.DataAgendada) && dataAgendada is null) return "Data agendada inválida. Use DD/MM/AAAA.";
        if (!string.IsNullOrWhiteSpace(Venda.HoraAgendada) && LerHora(Venda.HoraAgendada) is null) return "Hora agendada inválida. Use HH:MM.";
        if (Venda.Status == "Agendado" && dataAgendada is null) return "Para agendar, informe a data agendada.";
        if ((Venda.Observacao?.Length ?? 0) > 500) return "A observação pode ter no máximo 500 caracteres.";
        return null;
    }

    private async Task<VendaRequest> MontarRequestAsync(List<ItemForm> itens, (StatusVenda Venda, StatusPagamento Pagamento) status,
        FormaPagamento pagamento, DateTime? dataAgendada)
    {
        var delivery = Venda.TipoEntrega == "Delivery";

        // Taxa definida pelos gestores (Entregas → Pedido mínimo e taxa), sobre o subtotal dos itens.
        decimal taxa = 0;
        if (delivery)
        {
            decimal subtotal = 0;
            foreach (var item in itens)
            {
                var produto = await Produtos.GetByIdAsync(item.ProdutoId)
                    ?? throw new KeyNotFoundException($"Produto ID {item.ProdutoId} não encontrado.");
                subtotal += produto.PrecoVenda * item.Quantidade;
            }
            taxa = (await ConfigEntrega.ObterAsync()).CalcularTaxa(subtotal);
        }

        return new VendaRequest
        {
            ClienteId = Venda.ClienteId,
            Itens = itens.GroupBy(i => i.ProdutoId)
                .Select(g => new ItemVendaRequest { ProdutoId = g.Key, Quantidade = g.Sum(i => i.Quantidade) }).ToList(),
            Desconto = LerDesconto(),
            TipoDesconto = LerDesconto() == 0 ? TipoDesconto.Nenhum
                : Venda.TipoDesconto == "PCT" ? TipoDesconto.Percentual : TipoDesconto.Valor,
            Frete = taxa,
            Observacao = string.IsNullOrWhiteSpace(Venda.Observacao) ? null : Venda.Observacao.Trim(),
            Origem = Venda.Plataforma.Trim(),
            Status = status.Venda,
            Pagamento = new PagamentoRequest { FormaPagamento = pagamento, StatusPagamento = status.Pagamento },
            Entrega = new EntregaRequest
            {
                TipoEntrega = delivery ? TipoEntrega.Entrega : TipoEntrega.Retirada,
                DataEntrega = dataAgendada ?? DateTime.Today,
                Horario = LerHora(Venda.HoraAgendada) ?? string.Empty,
                ValorEntrega = taxa,
                Logradouro = delivery ? Venda.Rua?.Trim() : null,
                Numero = delivery ? Venda.Numero?.Trim() : null,
                Complemento = delivery && !string.IsNullOrWhiteSpace(Venda.Complemento) ? Venda.Complemento.Trim() : null,
                Bairro = delivery ? Venda.Bairro?.Trim() : null,
                Cidade = delivery && !string.IsNullOrWhiteSpace(Venda.Cidade) ? Venda.Cidade.Trim() : null,
                Estado = delivery && !string.IsNullOrWhiteSpace(Venda.Uf) ? Venda.Uf.Trim().ToUpper() : null
            }
        };
    }
}
