/// Como o cliente vai receber o pedido.
enum DeliveryType { delivery, pickup }

extension DeliveryTypeLabel on DeliveryType {
  String get label => switch (this) {
        DeliveryType.delivery => 'Receber no Endereço',
        DeliveryType.pickup => 'Retirar no Local',
      };
}
