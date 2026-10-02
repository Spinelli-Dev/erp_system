import 'address.dart';
import 'cart_item.dart';
import 'delivery_type.dart';
import 'payment_method.dart';

/// Pedido completo, pronto para ser enviado à API (ver [OrderService]).
class OrderRequest {
  const OrderRequest({
    required this.userId,
    required this.items,
    required this.total,
    required this.deliveryType,
    this.deliveryAddress,
    required this.paymentMethod,
    this.specialObservations = '',
    this.scheduledTime,
    required this.orderDate,
  });

  final String userId;
  final List<CartItem> items;
  final double total;
  final DeliveryType deliveryType;

  /// Preenchido apenas quando [deliveryType] é [DeliveryType.delivery];
  /// `null` para retirada no local.
  final Address? deliveryAddress;

  final PaymentMethod paymentMethod;
  final String specialObservations;

  /// Horário escolhido para a retirada (ex.: "19:30" ou "Assim que
  /// possível"); `null` na entrega.
  final String? scheduledTime;

  final DateTime orderDate;

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'items': items
            .map((item) => {
                  'productId': item.product.id,
                  'name': item.product.name,
                  'quantity': item.quantity,
                  'unitPrice': item.product.price,
                })
            .toList(),
        'total': total,
        'deliveryType': deliveryType.name,
        'deliveryAddress': deliveryAddress?.toJson(),
        'paymentMethod': paymentMethod.name,
        'specialObservations': specialObservations,
        'scheduledTime': scheduledTime,
        'orderDate': orderDate.toIso8601String(),
      };
}
