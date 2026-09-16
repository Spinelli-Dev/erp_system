// DTOs da integracao com a API publica ViaCEP.
using System.Text.Json.Serialization;

namespace MaxiMassasAPI.Integrations;

public class ViaCepResponseDto
{
    [JsonPropertyName("cep")] public string Cep { get; set; } = string.Empty;
    [JsonPropertyName("logradouro")] public string Logradouro { get; set; } = string.Empty;
    [JsonPropertyName("complemento")] public string Complemento { get; set; } = string.Empty;
    [JsonPropertyName("bairro")] public string Bairro { get; set; } = string.Empty;
    [JsonPropertyName("localidade")] public string Cidade { get; set; } = string.Empty;
    [JsonPropertyName("uf")] public string Estado { get; set; } = string.Empty;
    [JsonPropertyName("erro")] public bool? Erro { get; set; }
}

public class EnderecoDto
{
    public string CEP { get; set; } = string.Empty;
    public string Logradouro { get; set; } = string.Empty;
    public string Bairro { get; set; } = string.Empty;
    public string Localidade { get; set; } = string.Empty;
    public string UF { get; set; } = string.Empty;
    public string EnderecoCompleto =>
        $"{Logradouro}, {Bairro}, {Localidade} - {UF}";
}