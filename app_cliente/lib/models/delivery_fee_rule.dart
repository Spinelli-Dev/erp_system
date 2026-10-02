/// Regra da taxa de entrega, definida pelos gestores no sistema web: um
/// valor fixo, dispensado quando o subtotal chega ao pedido mínimo.
class DeliveryFeeRule {
  const DeliveryFeeRule({required this.fee, this.freeDeliveryFrom = 0});

  /// Usada sem API configurada (modo mock) e até a regra real chegar.
  static const padrao = DeliveryFeeRule(fee: 6.90);

  /// Valor fixo cobrado por entrega.
  final double fee;

  /// Subtotal a partir do qual a entrega sai grátis. Zero = sempre cobra.
  final double freeDeliveryFrom;

  bool get temEntregaGratis => freeDeliveryFrom > 0;

  double taxaPara(double subtotal) => temEntregaGratis && subtotal >= freeDeliveryFrom ? 0 : fee;

  /// Quanto falta para a entrega sair grátis; `null` se não há essa
  /// regra ou se o pedido já chegou lá.
  double? faltaParaGratis(double subtotal) {
    if (!temEntregaGratis || subtotal >= freeDeliveryFrom) return null;
    return freeDeliveryFrom - subtotal;
  }

  factory DeliveryFeeRule.fromJson(Map<String, dynamic> json) => DeliveryFeeRule(
        fee: (json['taxaEntrega'] as num?)?.toDouble() ?? 0,
        freeDeliveryFrom: (json['pedidoMinimoEntregaGratis'] as num?)?.toDouble() ?? 0,
      );
}
