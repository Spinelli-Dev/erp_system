// VendaService — atualizado para refletir o diagrama UML.
//
// MUDANÇAS CRÍTICAS vs versão anterior:
//   1. StatusPagamento migrado para entidade Pagamento
//   2. Status (StatusVenda) adicionado na Venda
//   3. Frete e Observacao suportados na criação
//   4. REDUÇÃO DE ESTOQUE ao finalizar venda (UML: regra 9)
//   5. MOVIMENTAÇÃO DE ESTOQUE registrada automaticamente
//   6. UpdateAsync pode atualizar status da venda E do pagamento separadamente
using AutoMapper;
using MaxiMassasAPI.Data;
using MaxiMassasAPI.DTOs.Request;
using MaxiMassasAPI.DTOs.Response;
using MaxiMassasAPI.Models;
using MaxiMassasAPI.Repositories;
using Microsoft.EntityFrameworkCore;

namespace MaxiMassasAPI.Services;

public class VendaService : IVendaService
{
    private readonly IVendaRepository _vendaRepo;
    private readonly IProdutoRepository _produtoRepo;
    private readonly IEstoqueRepository _estoqueRepo;
    private readonly IRepository<MovimentacaoEstoque> _movRepo;
    private readonly IMapper _mapper;
    private readonly ILogger<VendaService> _logger;

    public VendaService(
        IVendaRepository vendaRepo,
        IProdutoRepository produtoRepo,
        IEstoqueRepository estoqueRepo,
        IRepository<MovimentacaoEstoque> movRepo,
        IMapper mapper,
        ILogger<VendaService> logger)
    {
        _vendaRepo = vendaRepo;
        _produtoRepo = produtoRepo;
        _estoqueRepo = estoqueRepo;
        _movRepo = movRepo;
        _mapper = mapper;
        _logger = logger;
    }

    public async Task<IEnumerable<VendaResponse>> GetAllAsync()
        => _mapper.Map<IEnumerable<VendaResponse>>(await _vendaRepo.GetVendasComDetalhesAsync());

    public async Task<VendaResponse?> GetByIdAsync(int id)
    {
        var v = await _vendaRepo.GetVendaComDetalhesAsync(id);
        return v is null ? null : _mapper.Map<VendaResponse>(v);
    }

    /// <summary>
    /// Cria uma venda completa.
    ///
    /// FLUXO (UML regras 8 e 9):
    ///   1. Valida estoque disponível para cada item
    ///   2. Calcula subtotal por item e total da venda (+ frete - desconto)
    ///   3. Cria Pagamento com StatusPagamento inicial
    ///   4. Cria Entrega se informada
    ///   5. Persiste a venda
    ///   6. REDUZ O ESTOQUE de cada item (UML: ao finalizar venda, estoque deve ser reduzido)
    ///   7. REGISTRA MOVIMENTAÇÃO de saída para rastreabilidade
    /// </summary>
    public async Task<VendaResponse> CreateAsync(VendaRequest request, int usuarioId)
    {
        // ── FASE 1: Pré-validação de estoque ─────────────────────────────────
        // Valida TODOS os itens antes de persistir qualquer coisa
        // (evita situação em que alguns itens são baixados e outros não)
        foreach (var itemReq in request.Itens)
        {
            var estoqueItem = await _estoqueRepo.GetByProdutoIdAsync(itemReq.ProdutoId);
            if (estoqueItem is null)
                throw new InvalidOperationException(
                    $"Produto ID {itemReq.ProdutoId} não possui estoque cadastrado.");

            if (estoqueItem.Quantidade < itemReq.Quantidade)
                throw new InvalidOperationException(
                    $"Estoque insuficiente para o produto ID {itemReq.ProdutoId}. " +
                    $"Disponível: {estoqueItem.Quantidade}, Solicitado: {itemReq.Quantidade}.");
        }

        // ── FASE 2: Montagem da Venda ─────────────────────────────────────────
        var venda = new Venda
        {
            Data = DateTime.Now,
            ClienteId = request.ClienteId,
            UsuarioId = usuarioId,
            TipoDesconto = request.TipoDesconto,
            Desconto = request.Desconto,
            Frete = request.Frete,           // UML: Frete: decimal
            Observacao = request.Observacao, // UML: Observacao: string
            Origem = request.Origem,
            Status = StatusVenda.Aberta      // Inicia como Aberta, conclui ao finalizar
        };

        // ── FASE 3: Itens e cálculo de totais ────────────────────────────────
        decimal totalBruto = 0;
        foreach (var itemReq in request.Itens)
        {
            var produto = await _produtoRepo.GetByIdAsync(itemReq.ProdutoId)
                ?? throw new KeyNotFoundException($"Produto ID {itemReq.ProdutoId} não encontrado.");

            // Calcula subtotal do item (UML: ItemVenda.calcularSubtotal())
            var sub = produto.PrecoVenda * itemReq.Quantidade;
            totalBruto += sub;

            venda.ItensVenda.Add(new ItemVenda
            {
                ProdutoId = produto.Id,
                Quantidade = itemReq.Quantidade,
                PrecoUnitario = produto.PrecoVenda,
                Subtotal = sub
            });
        }

        // Calcula total: bruto - desconto + frete (UML: Venda.calcularTotal())
        var aposDesconto = request.TipoDesconto switch
        {
            TipoDesconto.Valor => totalBruto - request.Desconto,
            TipoDesconto.Percentual => totalBruto * (1 - request.Desconto / 100),
            _ => totalBruto
        };
        venda.ValorTotal = Math.Max(0, aposDesconto) + request.Frete;

        // ── FASE 4: Pagamento (UML: StatusPagamento agora em Pagamento) ───────
        var taxa = request.Pagamento.Taxa / 100;
        venda.Pagamento = new Pagamento
        {
            FormaPagamento = request.Pagamento.FormaPagamento,
            Taxa = request.Pagamento.Taxa,
            ValorFinal = venda.ValorTotal * (1 + taxa),
            StatusPagamento = request.Pagamento.StatusPagamento,
            DataPagamento = request.Pagamento.StatusPagamento == StatusPagamento.Pago
                ? (request.Pagamento.DataPagamento ?? DateTime.Now) : null,
            CodigoTransacao = request.Pagamento.CodigoTransacao,
            Observacao = request.Pagamento.Observacao
        };

        // Se já foi pago no ato da venda, conclui a venda
        if (request.Pagamento.StatusPagamento == StatusPagamento.Pago)
            venda.Status = StatusVenda.Concluida;

        // ── FASE 5: Entrega (opcional) ────────────────────────────────────────
        if (request.Entrega is not null)
        {
            var entrega = new Entrega
            {
                TipoEntrega = request.Entrega.TipoEntrega,
                DataEntrega = request.Entrega.DataEntrega,  // UML: DataEntrega
                Horario = request.Entrega.Horario,
                Taxa = request.Entrega.Taxa,                // UML: Taxa
                // ValorEntrega: usa o fixo informado; se zero, calcula pela taxa
                ValorEntrega = request.Entrega.ValorEntrega > 0
                    ? request.Entrega.ValorEntrega
                    : venda.ValorTotal * (request.Entrega.Taxa / 100)
            };
            venda.Entrega = entrega;
        }

        // ── FASE 6: Persiste a venda ──────────────────────────────────────────
        await _vendaRepo.AddAsync(venda);
        await _vendaRepo.SaveChangesAsync();

        // ── FASE 7: Redução de estoque (UML regra 9) ─────────────────────────
        // CRÍTICO: executado APÓS salvar a venda para ter o VendaId disponível
        await ReducirEstoqueAsync(venda);

        var salva = await _vendaRepo.GetVendaComDetalhesAsync(venda.Id);
        return _mapper.Map<VendaResponse>(salva!);
    }

    /// <summary>
    /// Reduz o estoque de cada item da venda e registra a movimentação.
    /// UML regra 9: "ao finalizar venda, estoque deve ser reduzido e movimentação registrada".
    /// </summary>
    private async Task ReducirEstoqueAsync(Venda venda)
    {
        foreach (var item in venda.ItensVenda)
        {
            var estoque = await _estoqueRepo.GetByProdutoIdAsync(item.ProdutoId)
                ?? throw new InvalidOperationException(
                    $"Estoque não encontrado para produto ID {item.ProdutoId}.");

            // Reduz a quantidade
            estoque.Quantidade -= item.Quantidade;
            _estoqueRepo.Update(estoque);

            // Registra movimentação de saída (Saida = venda ao cliente)
            var mov = new MovimentacaoEstoque
            {
                EstoqueId = estoque.Id,
                Tipo = TipoMovimentacao.Saida,
                Quantidade = item.Quantidade,
                Motivo = $"Venda #{venda.Id} — {DateTime.Now:dd/MM/yyyy HH:mm}",
                Data = DateTime.Now
            };
            await _movRepo.AddAsync(mov);

            // Alerta de estoque mínimo
            if (estoque.Quantidade <= estoque.AlertaMinimo)
                _logger.LogWarning(
                    "[Venda] Estoque baixo após venda #{VendaId}. ProdutoId={ProdutoId}, Qtd={Qtd}, Min={Min}",
                    venda.Id, item.ProdutoId, estoque.Quantidade, estoque.AlertaMinimo);
        }

        await _estoqueRepo.SaveChangesAsync();
        _logger.LogInformation(
            "[Venda] Estoque reduzido para {N} produto(s) da venda #{VendaId}.",
            venda.ItensVenda.Count, venda.Id);
    }

    /// <summary>
    /// Atualiza o status da venda e/ou do pagamento de forma independente.
    /// UML: StatusVenda em Venda; StatusPagamento em Pagamento.
    /// </summary>
    public async Task<VendaResponse?> UpdateAsync(int id, VendaUpdateRequest request)
    {
        // Carrega com Pagamento para poder atualizar StatusPagamento
        var venda = await _vendaRepo.GetVendaComDetalhesAsync(id);
        if (venda is null) return null;

        // Atualiza status do pedido
        venda.Status = request.Status;
        venda.Origem = request.Origem;

        // Atualiza status do pagamento na entidade Pagamento (UML)
        if (venda.Pagamento is not null)
        {
            venda.Pagamento.StatusPagamento = request.StatusPagamento;
            if (request.StatusPagamento == StatusPagamento.Pago)
                venda.Pagamento.DataPagamento = request.DataPagamento ?? DateTime.Now;
        }

        // Se pagamento aprovado e venda ainda aberta, conclui automaticamente
        if (request.StatusPagamento == StatusPagamento.Pago && venda.Status == StatusVenda.Aberta)
            venda.Status = StatusVenda.Concluida;

        _vendaRepo.Update(venda);
        await _vendaRepo.SaveChangesAsync();

        var atualizada = await _vendaRepo.GetVendaComDetalhesAsync(id);
        return _mapper.Map<VendaResponse>(atualizada!);
    }

    public async Task<bool> DeleteAsync(int id)
    {
        var v = await _vendaRepo.GetByIdAsync(id);
        if (v is null) return false;
        _vendaRepo.Remove(v);
        return await _vendaRepo.SaveChangesAsync();
    }
}
