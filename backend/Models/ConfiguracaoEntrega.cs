// Regra da taxa de entrega, definida pelos gestores na tela de Entregas do sistema web.
// Registro único (Id = 1), criado pela migration com os valores zerados.
namespace MaxiMassasAPI.Models;

public class ConfiguracaoEntrega
{
    public const int IdUnico = 1;

    public int Id { get; set; } = IdUnico;

    /// <summary>Valor fixo cobrado por entrega.</summary>
    public decimal TaxaEntrega { get; set; }

    /// <summary>
    /// Subtotal (soma dos itens) a partir do qual a entrega sai grátis.
    /// Zero = não há entrega grátis; a taxa é sempre cobrada.
    /// </summary>
    public decimal PedidoMinimoEntregaGratis { get; set; }

    public DateTime AtualizadoEm { get; set; } = DateTime.Now;

    /// <summary>Taxa a cobrar para um pedido de entrega com este subtotal.</summary>
    public decimal CalcularTaxa(decimal subtotal)
        => PedidoMinimoEntregaGratis > 0 && subtotal >= PedidoMinimoEntregaGratis ? 0m : TaxaEntrega;
}
