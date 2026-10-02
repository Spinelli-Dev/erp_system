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
    // Mesmo DbContext (scoped) dos repositórios: usado para a transação e para a baixa
    // atômica de estoque, que os repositórios genéricos não oferecem.
    private readonly AppDbContext _context;

    public VendaService(
        IVendaRepository vendaRepo,
        IProdutoRepository produtoRepo,
        IEstoqueRepository estoqueRepo,
        IRepository<MovimentacaoEstoque> movRepo,
        IMapper mapper,
        ILogger<VendaService> logger,
        AppDbContext context)
    {
        _vendaRepo = vendaRepo;
        _produtoRepo = produtoRepo;
        _estoqueRepo = estoqueRepo;
        _movRepo = movRepo;
        _mapper = mapper;
        _logger = logger;
        _context = context;
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
    public async Task<VendaResponse> CreateAsync(VendaRequest request, int? usuarioId)
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
            // Inicia como Aberta (ou o status pedido, ex.: "Agendado"); conclui ao finalizar.
            // Nunca nasce Cancelada nem Concluida por aqui (Concluida vem do pagamento Pago, abaixo).
            Status = request.Status is StatusVenda.EmProcessamento or StatusVenda.EmEntrega
                ? request.Status.Value
                : StatusVenda.Aberta
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
                Logradouro = request.Entrega.Logradouro,
                Numero = request.Entrega.Numero,
                Complemento = request.Entrega.Complemento,
                Bairro = request.Entrega.Bairro,
                Cep = request.Entrega.Cep,
                Cidade = request.Entrega.Cidade,
                Estado = request.Entrega.Estado,
                Taxa = request.Entrega.Taxa,                // UML: Taxa
                // ValorEntrega: usa o fixo informado; se zero, calcula pela taxa
                ValorEntrega = request.Entrega.ValorEntrega > 0
                    ? request.Entrega.ValorEntrega
                    : venda.ValorTotal * (request.Entrega.Taxa / 100)
            };
            venda.Entrega = entrega;
        }

        // ── FASES 6 e 7: Persiste a venda e baixa o estoque numa transação só ──
        // Se a baixa falhar (ex.: outro pedido levou as últimas unidades), a venda
        // também é desfeita — nunca fica venda sem baixa nem baixa sem venda.
        await using (var transacao = await _context.Database.BeginTransactionAsync())
        {
            await _vendaRepo.AddAsync(venda);
            await _vendaRepo.SaveChangesAsync();

            // CRÍTICO: executado APÓS salvar a venda para ter o VendaId disponível
            await BaixarEstoqueAsync(venda);
            await transacao.CommitAsync();
        }

        var salva = await _vendaRepo.GetVendaComDetalhesAsync(venda.Id);
        return _mapper.Map<VendaResponse>(salva!);
    }

    /// <summary>
    /// Reduz o estoque de cada item da venda e registra a movimentação.
    /// UML regra 9: "ao finalizar venda, estoque deve ser reduzido e movimentação registrada".
    ///
    /// CONCORRÊNCIA: a FASE 1 só confere o estoque (para dar uma mensagem amigável); quem
    /// garante de fato é o UPDATE condicional abaixo — "baixe N, desde que ainda haja N".
    /// O SQL Server trava a linha durante o UPDATE, então dois pedidos simultâneos pelas
    /// últimas unidades são atendidos um de cada vez: o segundo encontra o estoque já
    /// baixado, não altera nenhuma linha e a venda inteira é desfeita. O estoque nunca
    /// fica negativo.
    /// </summary>
    private async Task BaixarEstoqueAsync(Venda venda)
    {
        foreach (var item in venda.ItensVenda)
        {
            var quantidade = item.Quantidade;
            var linhas = await _context.Estoques
                .Where(e => e.ProdutoId == item.ProdutoId && e.Quantidade >= quantidade)
                .ExecuteUpdateAsync(s => s.SetProperty(e => e.Quantidade, e => e.Quantidade - quantidade));

            if (linhas == 0)
            {
                var nome = await _context.Produtos.AsNoTracking()
                    .Where(p => p.Id == item.ProdutoId).Select(p => p.Nome).FirstOrDefaultAsync();
                throw new InvalidOperationException(
                    $"Estoque insuficiente para {nome ?? $"o produto ID {item.ProdutoId}"}: as ultimas unidades " +
                    "acabaram de ser vendidas. Ajuste a quantidade e tente novamente.");
            }

            // ExecuteUpdate grava direto no banco; relê só para o alerta e a movimentação.
            var estoque = await _context.Estoques.AsNoTracking().FirstAsync(e => e.ProdutoId == item.ProdutoId);

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

        await _movRepo.SaveChangesAsync();
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

        var estavaCancelada = venda.Status == StatusVenda.Cancelada;
        var cancelando = !estavaCancelada && request.Status == StatusVenda.Cancelada;

        // Reabrir exigiria tirar do estoque de novo, e as unidades podem já ter sido vendidas.
        if (estavaCancelada && request.Status != StatusVenda.Cancelada)
            throw new InvalidOperationException(
                "Venda cancelada nao pode ser reaberta: os itens ja voltaram ao estoque. Registre uma nova venda.");

        // Atualiza status do pedido
        venda.Status = request.Status;
        venda.Origem = request.Origem;
        if (request.Observacao is not null)
            venda.Observacao = string.IsNullOrWhiteSpace(request.Observacao) ? null : request.Observacao.Trim();
        if (request.FormaPagamento is not null && venda.Pagamento is not null)
            venda.Pagamento.FormaPagamento = request.FormaPagamento.Value;

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

        // Cancelar devolve os itens ao estoque — na mesma transação da mudança de status.
        await using (var transacao = await _context.Database.BeginTransactionAsync())
        {
            _vendaRepo.Update(venda);
            await _vendaRepo.SaveChangesAsync();
            if (cancelando) await DevolverEstoqueAsync(venda);
            await transacao.CommitAsync();
        }

        var atualizada = await _vendaRepo.GetVendaComDetalhesAsync(id);
        return _mapper.Map<VendaResponse>(atualizada!);
    }

    /// <summary>Venda cancelada: cada item volta ao estoque, com movimentação de entrada registrada.</summary>
    private async Task DevolverEstoqueAsync(Venda venda)
    {
        foreach (var item in venda.ItensVenda)
        {
            var quantidade = item.Quantidade;
            await _context.Estoques
                .Where(e => e.ProdutoId == item.ProdutoId)
                .ExecuteUpdateAsync(s => s.SetProperty(e => e.Quantidade, e => e.Quantidade + quantidade));

            var estoqueId = await _context.Estoques.AsNoTracking()
                .Where(e => e.ProdutoId == item.ProdutoId).Select(e => (int?)e.Id).FirstOrDefaultAsync();
            if (estoqueId is null) continue;

            await _movRepo.AddAsync(new MovimentacaoEstoque
            {
                EstoqueId = estoqueId.Value,
                Tipo = TipoMovimentacao.Entrada,
                Quantidade = quantidade,
                Motivo = $"Cancelamento da venda #{venda.Id} — {DateTime.Now:dd/MM/yyyy HH:mm}",
                Data = DateTime.Now
            });
        }
        await _movRepo.SaveChangesAsync();
        _logger.LogInformation("[Venda] Venda #{VendaId} cancelada: {N} item(ns) devolvido(s) ao estoque.",
            venda.Id, venda.ItensVenda.Count);
    }

    public async Task<bool> DeleteAsync(int id)
    {
        var v = await _vendaRepo.GetByIdAsync(id);
        if (v is null) return false;
        _vendaRepo.Remove(v);
        return await _vendaRepo.SaveChangesAsync();
    }
}
