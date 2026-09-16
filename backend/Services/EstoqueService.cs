using AutoMapper;
using MaxiMassasAPI.DTOs.Request;
using MaxiMassasAPI.DTOs.Response;
using MaxiMassasAPI.Models;
using MaxiMassasAPI.Repositories;

namespace MaxiMassasAPI.Services;

public class EstoqueService : IEstoqueService
{
    private readonly IEstoqueRepository _estoqueRepo;
    private readonly IRepository<MovimentacaoEstoque> _movRepo;
    private readonly IMapper _mapper;
    private readonly ILogger<EstoqueService> _logger;

    public EstoqueService(IEstoqueRepository er, IRepository<MovimentacaoEstoque> mr, IMapper mapper, ILogger<EstoqueService> logger)
    { _estoqueRepo = er; _movRepo = mr; _mapper = mapper; _logger = logger; }

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

    public async Task<EstoqueResponse?> RegistrarMovimentacaoAsync(MovimentacaoEstoqueRequest request)
    {
        var estoque = await _estoqueRepo.GetByIdAsync(request.EstoqueId);
        if (estoque is null) return null;
        if (request.Tipo == TipoMovimentacao.Saida && estoque.Quantidade < request.Quantidade)
            throw new InvalidOperationException($"Estoque insuficiente. Disponivel: {estoque.Quantidade}");
        estoque.Quantidade = request.Tipo == TipoMovimentacao.Entrada
            ? estoque.Quantidade + request.Quantidade
            : estoque.Quantidade - request.Quantidade;
        var mov = new MovimentacaoEstoque
        {
            EstoqueId = request.EstoqueId, Tipo = request.Tipo,
            Motivo = request.Motivo, Quantidade = request.Quantidade, Data = DateTime.Now
        };
        _estoqueRepo.Update(estoque);
        await _movRepo.AddAsync(mov);
        await _estoqueRepo.SaveChangesAsync();
        if (estoque.Quantidade <= estoque.AlertaMinimo)
            _logger.LogWarning("ALERTA: Estoque baixo para produto ID {ProdutoId}. Qtd: {Qtd}", estoque.ProdutoId, estoque.Quantidade);
        return _mapper.Map<EstoqueResponse>(estoque);
    }

    public async Task<IEnumerable<EstoqueResponse>> GetEstoquesBaixosAsync()
        => _mapper.Map<IEnumerable<EstoqueResponse>>(await _estoqueRepo.GetEstoquesBaixosAsync());
}