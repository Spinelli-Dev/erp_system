namespace MaxiMassasAPI.Integrations;

public interface IViaCepService
{
    Task<EnderecoDto?> BuscarEnderecoPorCepAsync(string cep);
}