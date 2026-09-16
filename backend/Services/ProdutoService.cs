// ProdutoService — atualizado para registrar HistoricoPreco com novos campos UML.
// MotivoAlteracao e DataFimVigencia agora são registrados no histórico.
using AutoMapper;
using MaxiMassasAPI.DTOs.Request;
using MaxiMassasAPI.DTOs.Response;
using MaxiMassasAPI.Models;
using MaxiMassasAPI.Repositories;
using Microsoft.EntityFrameworkCore;

namespace MaxiMassasAPI.Services;

public class ProdutoService : IProdutoService
{
    private readonly IProdutoRepository _repo;
    private readonly IMapper _mapper;

    public ProdutoService(IProdutoRepository repo, IMapper mapper) { _repo = repo; _mapper = mapper; }

    public async Task<IEnumerable<ProdutoResponse>> GetAllAsync()
        => _mapper.Map<IEnumerable<ProdutoResponse>>(await _repo.GetAllComEstoqueAsync());

    public async Task<ProdutoResponse?> GetByIdAsync(int id)
    {
        var p = await _repo.GetProdutoComDetalhesAsync(id);
        return p is null ? null : _mapper.Map<ProdutoResponse>(p);
    }

    public async Task<ProdutoResponse> CreateAsync(ProdutoRequest request)
    {
        var produto = _mapper.Map<Produto>(request);
        await _repo.AddAsync(produto);
        await _repo.SaveChangesAsync();
        return _mapper.Map<ProdutoResponse>(produto);
    }

    /// <summary>
    /// Atualiza produto. Se o preço mudou:
    ///   1. Encerra a vigência do histórico anterior (DataFimVigencia = hoje)
    ///   2. Registra novo registro com MotivoAlteracao e DataFimVigencia nulo (vigente)
    /// UML: HistoricoPreco.MotivoAlteracao, DataFimVigencia
    /// </summary>
    public async Task<ProdutoResponse?> UpdateAsync(int id, ProdutoUpdateRequest request)
    {
        var produto = await _repo.GetByIdAsync(id);
        if (produto is null) return null;

        if (produto.PrecoVenda != request.PrecoVenda)
        {
            produto.HistoricoPreco ??= new List<HistoricoPreco>();

            // Encerra vigência do histórico mais recente sem DataFimVigencia
            // (necessário buscar via contexto pois produto pode não ter os histories carregados)
            var historicoAtivo = produto.HistoricoPreco
                .Where(h => h.DataFimVigencia == null)
                .ToList();
            foreach (var h in historicoAtivo)
                h.DataFimVigencia = DateTime.Now;

            // Registra novo histórico com campos do UML
            produto.HistoricoPreco.Add(new HistoricoPreco
            {
                PrecoAnterior = produto.PrecoVenda,
                DataAlteracao = DateTime.Now,
                ProdutoId = produto.Id,
                MotivoAlteracao = request.MotivoAlteracao,  // UML: MotivoAlteracao
                DataFimVigencia = null                       // UML: vigente até próxima alteração
            });
        }

        produto.Nome = request.Nome;
        produto.Peso = request.Peso;
        produto.PrecoVenda = request.PrecoVenda;
        produto.Custo = request.Custo;
        produto.Tipo = request.Tipo;

        _repo.Update(produto);
        await _repo.SaveChangesAsync();
        return _mapper.Map<ProdutoResponse>(produto);
    }

    public async Task<bool> DeleteAsync(int id)
    {
        var p = await _repo.GetByIdAsync(id);
        if (p is null) return false;
        _repo.Remove(p);
        return await _repo.SaveChangesAsync();
    }
}
