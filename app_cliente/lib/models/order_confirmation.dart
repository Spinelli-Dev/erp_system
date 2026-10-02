import 'address.dart';
import 'cart_item.dart';
import 'delivery_type.dart';
import 'franchise_info.dart';
import 'order_status.dart';
import 'payment_method.dart';

/// Retrato completo de um pedido já confirmado pelo backend — o que a
/// tela de confirmação (e o histórico "Meus Pedidos") precisam para se
/// desenhar sem depender mais do `CartProvider` (que já foi limpo nesse
/// ponto) nem da tela de checkout.
class OrderConfirmation {
  const OrderConfirmation({
    required this.orderId,
    required this.orderDate,
    required this.deliveryType,
    this.deliveryAddress,
    required this.pickupLocation,
    required this.items,
    required this.paymentMethod,
    required this.subtotal,
    required this.deliveryFee,
    this.discount = 0,
    required this.total,
    this.specialObservations = '',
    required this.estimatedTimeMinutes,
    required this.paymentInstructions,
    this.status = OrderStatus.recebido,
  });

  final String orderId;
  final DateTime orderDate;
  final DeliveryType deliveryType;

  /// Preenchido apenas quando [deliveryType] é [DeliveryType.delivery].
  final Address? deliveryAddress;

  /// Dados da franquia — usados tanto para "retirar no local" quanto
  /// como contato de dúvidas, independente do tipo de entrega.
  final FranchiseInfo pickupLocation;

  final List<CartItem> items;
  final PaymentMethod paymentMethod;
  final double subtotal;
  final double deliveryFee;

  /// Desconto de cupom aplicado. O app ainda não tem cadastro de cupons,
  /// então hoje sempre chega como 0 — o campo já existe para quando essa
  /// funcionalidade for implementada.
  final double discount;

  final double total;
  final String specialObservations;

  /// Tempo estimado (preparo, se retirada; preparo + trajeto, se entrega).
  final int estimatedTimeMinutes;

  /// Texto pronto com as instruções de pagamento (ver
  /// `core/payment_instructions.dart`), já formatado conforme a forma de
  /// pagamento escolhida.
  final String paymentInstructions;

  /// Situação atual do pedido. Vem do backend no histórico; um pedido
  /// recém-enviado começa como [OrderStatus.recebido].
  final OrderStatus status;
}
