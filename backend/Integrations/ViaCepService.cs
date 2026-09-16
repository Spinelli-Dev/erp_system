// Integracao com ViaCEP usando IHttpClientFactory.
// Fluxo: Validar CEP -> Normalizar -> GET API -> Tratar resposta -> Retornar EnderecoDto.
using System.Text.Json;

namespace MaxiMassasAPI.Integrations;

public class ViaCepService : IViaCepService
{
    private readonly IHttpClientFactory _httpClientFactory;
    private readonly ILogger<ViaCepService> _logger;

    public ViaCepService(IHttpClientFactory httpClientFactory, ILogger<ViaCepService> logger)
    {
        _httpClientFactory = httpClientFactory;
        _logger = logger;
    }

    public async Task<EnderecoDto?> BuscarEnderecoPorCepAsync(string cep)
    {
        var cepNorm = new string(cep.Where(char.IsDigit).ToArray());
        if (cepNorm.Length != 8)
        {
            _logger.LogWarning("CEP invalido: {Cep}", cep);
            return null;
        }

        try
        {
            _logger.LogInformation("Consultando ViaCEP para CEP: {Cep}", cepNorm);
            var client = _httpClientFactory.CreateClient("ViaCep");
            var response = await client.GetAsync($"{cepNorm}/json/");

            if (!response.IsSuccessStatusCode)
            {
                _logger.LogWarning("ViaCEP retornou status {Status} para CEP {Cep}", response.StatusCode, cepNorm);
                return null;
            }

            var json = await response.Content.ReadAsStringAsync();
            var resultado = JsonSerializer.Deserialize<ViaCepResponseDto>(json,
                new JsonSerializerOptions { PropertyNameCaseInsensitive = true });

            if (resultado == null || resultado.Erro == true)
            {
                _logger.LogWarning("CEP {Cep} nao encontrado na base ViaCEP.", cepNorm);
                return null;
            }

            var endereco = new EnderecoDto
            {
                CEP = resultado.Cep,
                Logradouro = resultado.Logradouro,
                Bairro = resultado.Bairro,
                Localidade = resultado.Cidade,
                UF = resultado.Estado
            };

            _logger.LogInformation("CEP {Cep} resolvido: {Endereco}", cepNorm, endereco.EnderecoCompleto);
            return endereco;
        }
        catch (TaskCanceledException ex) when (ex.InnerException is TimeoutException)
        {
            _logger.LogError(ex, "Timeout ao consultar ViaCEP para o CEP {Cep}.", cepNorm);
            return null;
        }
        catch (HttpRequestException ex)
        {
            _logger.LogError(ex, "Erro de rede ao consultar ViaCEP para CEP {Cep}.", cepNorm);
            return null;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Erro inesperado ao consultar ViaCEP para CEP {Cep}.", cepNorm);
            return null;
        }
    }
}