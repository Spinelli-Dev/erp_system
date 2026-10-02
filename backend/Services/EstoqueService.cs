using AutoMapper;
using MaxiMassasAPI.Data;
using MaxiMassasAPI.DTOs.Request;
using MaxiMassasAPI.DTOs.Response;
using MaxiMassasAPI.Models;
using MaxiMassasAPI.Repositories;
using Microsoft.EntityFrameworkCore;

namespace MaxiMassasAPI.Services;

public class EstoqueService : IEstoqueService
{
    private readonly IEstoqueRepository _estoqueRepo;
    private readonly IRepository<MovimentacaoEstoque> _movRepo;
    private readonly IMapper _mapper;
    private readonly ILogger<EstoqueService> _logger;
    // Mesmo DbContext (scoped) dos repositórios: para as atualizações atômicas de quantidade.
    private readonly AppDbContext _context;

    public EstoqueService(IEstoqueRepository er, IRepository<MovimentacaoEstoque> mr, IMapper mapper, ILogger<EstoqueService> logger,
        AppDbContext context)
    { _estoqueRepo = er; _movRepo = mr; _mapper = mapper; _logger = logger; _context = context; }

    public async Task<IEnumerable<EstoqueResponse>> GetAllAsync()
        => _mapper.Map<IEnumerable<EstoqueResponse>>(await _estoqueRepo.GetAllAsync());

    public async Task<EstoqueResponse?> GetByProdutoIdAsync(int produtoId)
    {
        var e = await _estoqueRepo.GetByProdutoIdAsync(produtoId);
        return e is null ? null : _mapper.Map<EstoqueResponse>(e);
    }

    public async Task<EstoqueResponse?> GetComMovimentacoesAsync(int id)
    {
        var e = await _estoqueRepo.GetComMovimentacoesAsync(id);
        return e is null ? null : _mapper.Map<EstoqueResponse>(e);
    }

    public async Task<EstoqueResponse> CreateAsync(EstoqueRequest request)
    {
        var estoque = _mapper.Map<Estoque>(request);
        await _estoqueRepo.AddAsync(estoque);
        await _estoqueRepo.SaveChangesAsync();
        return _mapper.Map<EstoqueResponse>(estoque);
    }

    /// <summary>
    /// Entrada soma; Saída, Perda e Consumo próprio subtraem — todas conferindo o saldo (antes só a Saída
    /// conferia, e Perda/Consumo podiam deixar o estoque negativo). A conta é feita num UPDATE atômico,
    /// como na baixa de vendas: uma venda simultânea nunca é perdida nem deixa o estoque negativo.
    /// </summary>
    public async Task<EstoqueResponse?> RegistrarMovimentacaoAsync(MovimentacaoEstoqueRequest request)
    {
        if (request.Tipo == TipoMovimentacao.Ajuste)
            throw new InvalidOperationException("Ajuste define uma quantidade exata: use o ajuste de estoque, nao uma movimentacao.");

        var existe = await _context.Estoques.AnyAsync(e => e.Id == request.EstoqueId);
        if (!existe) return null;

        var quantidade = request.Quantidade;
        int linhas;
        if (request.Tipo == TipoMovimentacao.Entrada)
        {
            linhas = await _context.Estoques.Where(e => e.Id == request.EstoqueId)
                .ExecuteUpdateAsync(s => s.SetProperty(e => e.Quantidade, e => e.Quantidade + quantidade));
        }
        else
        {
            linhas = await _context.Estoques.Where(e => e.Id == request.EstoqueId && e.Quantidade >= quantidade)
                .ExecuteUpdateAsync(s => s.SetProperty(e => e.Quantidade, e => e.Quantidade - quantidade));
            if (linhas == 0)
            {
                var disponivel = await _context.Estoques.Where(e => e.Id == request.EstoqueId).Select(e => e.Quantidade).FirstAsync();
                throw new InvalidOperationException($"Estoque insuficiente. Disponivel: {disponivel}");
            }
        }

        await RegistrarAsync(request.EstoqueId, request.Tipo, quantidade, request.Motivo);
        return await RecarregarAsync(request.EstoqueId);
    }

    public async Task<EstoqueResponse> GarantirEstoqueAsync(int produtoId, int alertaMinimo = 0)
    {
        var existente = await _estoqueRepo.GetByProdutoIdAsync(produtoId);
        if (existente is not null) return _mapper.Map<EstoqueResponse>(existente);
        return await CreateAsync(new EstoqueRequest { ProdutoId = produtoId, Quantidade = 0, AlertaMinimo = alertaMinimo });
    }

    public async Task<EstoqueResponse> AjustarQuantidadeAsync(int produtoId, int novaQuantidade, string? motivo = null)
    {
        if (novaQuantidade < 0) throw new InvalidOperationException("A quantidade em estoque nao pode ser negativa.");

        var estoque = await GarantirEstoqueAsync(produtoId);
        var anterior = await _context.Estoques.Where(e => e.Id == estoque.Id).Select(e => e.Quantidade).FirstAsync();
        if (anterior == novaQuantidade) return estoque;

        // Vale o número contado, mesmo que uma venda tenha acabado de baixar: é a contagem física.
        await _context.Estoques.Where(e => e.Id == estoque.Id)
            .ExecuteUpdateAsync(s => s.SetProperty(e => e.Quantidade, novaQuantidade));
        var texto = string.IsNullOrWhiteSpace(motivo) ? "Ajuste de inventario" : motivo.Trim();
        await RegistrarAsync(estoque.Id, TipoMovimentacao.Ajuste, Math.Abs(novaQuantidade - anterior),
            $"{texto}: de {anterior} para {novaQuantidade}");

        _logger.LogInformation("[Estoque] Produto {ProdutoId} ajustado de {De} para {Para}.", produtoId, anterior, novaQuantidade);
        return (await RecarregarAsync(estoque.Id))!;
    }

    private async Task RegistrarAsync(int estoqueId, TipoMovimentacao tipo, int quantidade, string motivo)
    {
        await _movRepo.AddAsync(new MovimentacaoEstoque
        {
            EstoqueId = estoqueId, Tipo = tipo, Quantidade = quantidade, Motivo = motivo, Data = DateTime.Now
        });
        await _movRepo.SaveChangesAsync();
    }

    private async Task<EstoqueResponse?> RecarregarAsync(int estoqueId)
    {
        var estoque = await _context.Estoques.AsNoTracking().FirstOrDefaultAsync(e => e.Id == estoqueId);
        if (estoque is not null && estoque.Quantidade <= estoque.AlertaMinimo)
            _logger.LogWarning("ALERTA: Estoque baixo para produto ID {ProdutoId}. Qtd: {Qtd}", estoque.ProdutoId, estoque.Quantidade);
        return estoque is null ? null : _mapper.Map<EstoqueResponse>(estoque);
    }

    public async Task<IEnumerable<EstoqueResponse>> GetEstoquesBaixosAsync()
        => _mapper.Map<IEnumerable<EstoqueResponse>>(await _estoqueRepo.GetEstoquesBaixosAsync());
}