using AutoMapper;
using MaxiMassasAPI.DTOs.Request;
using MaxiMassasAPI.DTOs.Response;
using MaxiMassasAPI.Integrations;
using MaxiMassasAPI.Models;
using MaxiMassasAPI.Repositories;
using System.Text.RegularExpressions;

namespace MaxiMassasAPI.Services;

public class ClienteService : IClienteService
{
    private readonly IClienteRepository _repo;
    private readonly IViaCepService _viacep;
    private readonly IMapper _mapper;
    private readonly ILogger<ClienteService> _logger;

    public ClienteService(
        IClienteRepository repo,
        IViaCepService viacep,
        IMapper mapper,
        ILogger<ClienteService> logger)
    {
        _repo = repo;
        _viacep = viacep;
        _mapper = mapper;
        _logger = logger;
    }

    public async Task<IEnumerable<ClienteResponse>> GetAllAsync()
        => _mapper.Map<IEnumerable<ClienteResponse>>(await _repo.GetAllAsync());

    public async Task<ClienteResponse?> GetByIdAsync(int id)
    {
        var cliente = await _repo.GetByIdAsync(id);

        return cliente is null
            ? null
            : _mapper.Map<ClienteResponse>(cliente);
    }

    public async Task<ClienteResponse> CreateAsync(ClienteRequest request)
    {
        var cliente = _mapper.Map<Cliente>(request);

        // Remove mascara do telefone
        cliente.Telefone = Regex.Replace(request.Telefone, @"\D", "");

        // Remove mascara do CEP
        cliente.CEP = Regex.Replace(request.CEP, @"\D", "");

        await PreencherEnderecoAsync(cliente, request, consultarCep: true);

        await _repo.AddAsync(cliente);
        await _repo.SaveChangesAsync();

        return _mapper.Map<ClienteResponse>(cliente);
    }

    public async Task<ClienteResponse?> UpdateAsync(int id, ClienteUpdateRequest request)
    {
        var cliente = await _repo.GetByIdAsync(id);

        if (cliente is null)
            return null;

        cliente.Nome = request.Nome;

        cliente.Telefone = Regex.Replace(request.Telefone, @"\D", "");

        cliente.Numero = request.Numero;

        cliente.Complemento = request.Complemento;

        cliente.Observacao = request.Observacao;

        if (request.Cpf is not null)
            cliente.Cpf = request.Cpf;

        var novoCep = Regex.Replace(request.CEP, @"\D", "");
        var cepMudou = cliente.CEP != novoCep;
        cliente.CEP = novoCep;

        // CEP novo: busca o endereço dele (o que foi digitado continua valendo)
        await PreencherEnderecoAsync(cliente, request, consultarCep: cepMudou);

        _repo.Update(cliente);

        await _repo.SaveChangesAsync();

        return _mapper.Map<ClienteResponse>(cliente);
    }

    /// <summary>
    /// Rua, bairro, cidade e UF: vale o que foi digitado; o que vier vazio sai do ViaCEP
    /// (quando [consultarCep]) ou fica como estava. Se o ViaCEP não achar o CEP, o
    /// endereço digitado é gravado do mesmo jeito (antes o endereço ficava em branco).
    /// </summary>
    private async Task PreencherEnderecoAsync(Cliente cliente, ClienteRequest request, bool consultarCep)
    {
        static string? Texto(string? s) => string.IsNullOrWhiteSpace(s) ? null : s.Trim();

        var faltaAlgo = Texto(request.Logradouro) is null || Texto(request.Bairro) is null
                        || Texto(request.Cidade) is null || Texto(request.Estado) is null;
        var viaCep = consultarCep && faltaAlgo ? await _viacep.BuscarEnderecoPorCepAsync(cliente.CEP) : null;

        if (consultarCep && faltaAlgo)
        {
            if (viaCep is not null)
                _logger.LogInformation("Endereco completado via ViaCEP para o CEP {CEP}.", cliente.CEP);
            else
                _logger.LogWarning("ViaCEP nao retornou endereco para o CEP {CEP}.", cliente.CEP);
        }

        cliente.Logradouro = Texto(request.Logradouro) ?? Texto(viaCep?.Logradouro) ?? Texto(cliente.Logradouro) ?? string.Empty;
        cliente.Bairro = Texto(request.Bairro) ?? Texto(viaCep?.Bairro) ?? Texto(cliente.Bairro) ?? string.Empty;
        cliente.Cidade = Texto(request.Cidade) ?? Texto(viaCep?.Localidade) ?? Texto(cliente.Cidade) ?? string.Empty;
        cliente.Estado = (Texto(request.Estado) ?? Texto(viaCep?.UF) ?? Texto(cliente.Estado) ?? string.Empty).ToUpper();
    }

    public async Task<bool> DeleteAsync(int id)
    {
        var cliente = await _repo.GetByIdAsync(id);

        if (cliente is null)
            return false;

        _repo.Remove(cliente);

        return await _repo.SaveChangesAsync();
    }

    public async Task<EnderecoDto?> BuscarEnderecoPorCepAsync(string cep)
    {
        cep = Regex.Replace(cep, @"\D", "");

        return await _viacep.BuscarEnderecoPorCepAsync(cep);
    }
}