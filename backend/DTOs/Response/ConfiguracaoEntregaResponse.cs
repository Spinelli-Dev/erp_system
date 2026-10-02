namespace MaxiMassasAPI.DTOs.Response;

public class ConfiguracaoEntregaResponse
{
    public decimal TaxaEntrega { get; set; }
    public decimal PedidoMinimoEntregaGratis { get; set; }
    public DateTime AtualizadoEm { get; set; }
}
