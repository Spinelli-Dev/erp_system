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

        // Busca endereco automaticamente pelo ViaCEP
        var endereco = await _viacep.BuscarEnderecoPorCepAsync(cliente.CEP);

        if (endereco is not null)
        {
            cliente.Logradouro = endereco.Logradouro;
            cliente.Bairro = endereco.Bairro;
            cliente.Cidade = endereco.Localidade;
            cliente.Estado = endereco.UF;

            _logger.LogInformation(
                "Endereco preenchido via ViaCEP para o CEP {CEP}.",
                cliente.CEP);
        }
        else
        {
            _logger.LogWarning(
                "ViaCEP nao retornou endereco para o CEP {CEP}.",
                cliente.CEP);
        }

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

        var novoCep = Regex.Replace(request.CEP, @"\D", "");

        // Atualiza endereco caso o CEP tenha sido alterado
        if (cliente.CEP != novoCep)
        {
            var endereco = await _viacep.BuscarEnderecoPorCepAsync(novoCep);

            if (endereco is not null)
            {
                cliente.CEP = novoCep;
                cliente.Logradouro = endereco.Logradouro;
                cliente.Bairro = endereco.Bairro;
                cliente.Cidade = endereco.Localidade;
                cliente.Estado = endereco.UF;

                _logger.LogInformation(
                    "Endereco atualizado automaticamente via ViaCEP.");
            }
        }

        _repo.Update(cliente);

        await _repo.SaveChangesAsync();

        return _mapper.Map<ClienteResponse>(cliente);
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