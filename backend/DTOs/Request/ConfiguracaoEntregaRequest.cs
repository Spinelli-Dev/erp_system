namespace MaxiMassasAPI.DTOs.Request;

/// <summary>Regra da taxa de entrega, editada pelos gestores na tela de Entregas.</summary>
public class ConfiguracaoEntregaRequest
{
    /// <summary>Valor fixo cobrado por entrega.</summary>
    public decimal TaxaEntrega { get; set; }

    /// <summary>Subtotal a partir do qual a entrega sai grátis. Zero = sempre cobra a taxa.</summary>
    public decimal PedidoMinimoEntregaGratis { get; set; }
}
