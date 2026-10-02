import '../core/payment_instructions.dart';
import '../models/address.dart';
import '../models/cart_item.dart';
import '../models/delivery_type.dart';
import '../models/order_confirmation.dart';
import '../models/order_request.dart';
import '../models/order_status.dart';
import '../models/payment_method.dart';
import '../models/product.dart';
import 'api_client.dart';
import 'franchise_service.dart';

/// Resultado do envio de um pedido.
class OrderResult {
  const OrderResult({
    required this.success,
    this.orderNumber,
    this.errorMessage,
    this.subtotal,
    this.deliveryFee,
    this.total,
  });

  final bool success;
  final String? orderNumber;
  final String? errorMessage;

  /// Valores calculados pelo servidor — a taxa de entrega e os preços
  /// valem os de lá. `null` no mock, que não calcula nada.
  final double? subtotal;
  final double? deliveryFee;
  final double? total;
}

/// Contrato de envio de pedidos: [ApiOrderService] fala com o backend
/// (`POST /api/app/pedidos`); [MockOrderService] simula a resposta
/// quando o app roda sem API configurada (ver `main.dart`).
abstract class OrderService {
  Future<OrderResult> enviarPedido(OrderRequest pedido);
}

/// Histórico de pedidos do cliente logado, mais recentes primeiro.
abstract class OrderHistoryService {
  Future<List<OrderConfirmation>> buscarPedidos();
}

/// Pedidos pela API. O pedido vira uma venda com origem "App" e aparece
/// na tela de vendas dos gestores; preço, taxa de entrega e estoque são
/// conferidos lá, não aqui.
class ApiOrderService implements OrderService, OrderHistoryService {
  ApiOrderService(this._api);

  final ApiClient _api;

  @override
  Future<OrderResult> enviarPedido(OrderRequest pedido) async {
    try {
      final data = await _api.post('/app/pedidos', _corpo(pedido)) as Map<String, dynamic>;
      return OrderResult(
        success: true,
        orderNumber: data['numero'] as String?,
        subtotal: _decimal(data['subtotal']),
        deliveryFee: _decimal(data['taxaEntrega']),
        total: _decimal(data['total']),
      );
    } on ApiException catch (erro) {
      return OrderResult(
        success: false,
        errorMessage: erro.naoAutorizado ? 'Sua sessão expirou. Entre novamente.' : erro.message,
      );
    }
  }

  @override
  Future<List<OrderConfirmation>> buscarPedidos() async {
    final data = await _api.get('/app/pedidos') as List<dynamic>;
    return [for (final json in data.cast<Map<String, dynamic>>()) _pedidoDaApi(json)];
  }

  Map<String, dynamic> _corpo(OrderRequest pedido) {
    final endereco = pedido.deliveryAddress;
    return {
      'itens': [
        for (final item in pedido.items) {'produtoId': int.parse(item.product.id), 'quantidade': item.quantity},
      ],
      'tipoEntrega': pedido.deliveryType == DeliveryType.delivery ? 'Entrega' : 'Retirada',
      if (endereco != null)
        'endereco': {
          'logradouro': endereco.street,
          'numero': endereco.number,
          'complemento': endereco.complement,
          'bairro': endereco.neighborhood,
          'cep': endereco.zipCode,
          'cidade': endereco.city,
          'estado': endereco.state,
        },
      'horario': pedido.scheduledTime,
      'formaPagamento': switch (pedido.paymentMethod) {
        PaymentMethod.cash => 'Dinheiro',
        // O app não pergunta crédito/débito; o pagamento é feito na entrega.
        PaymentMethod.card => 'CartaoCredito',
        PaymentMethod.pix => 'Pix',
      },
      'observacao': pedido.specialObservations,
    };
  }

  OrderConfirmation _pedidoDaApi(Map<String, dynamic> json) {
    final entrega = json['tipoEntrega'] == 'Entrega' ? DeliveryType.delivery : DeliveryType.pickup;
    final pagamento = switch (json['formaPagamento']) {
      'Dinheiro' => PaymentMethod.cash,
      'Pix' => PaymentMethod.pix,
      _ => PaymentMethod.card,
    };
    final total = _decimal(json['total']) ?? 0;
    final endereco = json['endereco'] as Map<String, dynamic>?;

    return OrderConfirmation(
      orderId: json['numero'] as String? ?? '#${json['id']}',
      orderDate: DateTime.parse(json['data'] as String),
      deliveryType: entrega,
      deliveryAddress: endereco == null
          ? null
          : Address(
              street: endereco['logradouro'] as String? ?? '',
              number: endereco['numero'] as String? ?? '',
              complement: endereco['complemento'] as String? ?? '',
              neighborhood: endereco['bairro'] as String? ?? '',
              zipCode: endereco['cep'] as String? ?? '',
              city: endereco['cidade'] as String? ?? '',
              state: endereco['estado'] as String? ?? '',
            ),
      pickupLocation: franquiaPadrao,
      // O produto guarda o preço PAGO no pedido; "Pedir de novo" confere o
      // preço e a disponibilidade atuais pelo id, no cardápio.
      items: [
        for (final item in (json['itens'] as List<dynamic>).cast<Map<String, dynamic>>())
          CartItem(
            product: Product(
              id: item['produtoId'].toString(),
              name: item['nome'] as String? ?? '',
              description: '',
              price: _decimal(item['precoUnitario']) ?? 0,
              category: '',
            ),
            quantity: item['quantidade'] as int? ?? 1,
          ),
      ],
      paymentMethod: pagamento,
      subtotal: _decimal(json['subtotal']) ?? 0,
      deliveryFee: _decimal(json['taxaEntrega']) ?? 0,
      total: total,
      specialObservations: json['observacao'] as String? ?? '',
      estimatedTimeMinutes: entrega == DeliveryType.delivery
          ? franquiaPadrao.tempoEntregaMinutos
          : franquiaPadrao.tempoPreparoMinutos,
      paymentInstructions: gerarInstrucoesPagamento(method: pagamento, total: total, franquia: franquiaPadrao),
      status: OrderStatusDisplay.daApi(json['status'] as String?),
    );
  }

  static double? _decimal(dynamic valor) => (valor as num?)?.toDouble();
}

/// Implementação mockada, usada quando o app roda sem API configurada.
class MockOrderService implements OrderService {
  @override
  Future<OrderResult> enviarPedido(OrderRequest pedido) async {
    await Future.delayed(const Duration(milliseconds: 1400));

    final sufixo = pedido.orderDate.millisecondsSinceEpoch.toString();
    final numero = '#MM${sufixo.substring(sufixo.length - 6)}';
    return OrderResult(success: true, orderNumber: numero);
  }
}
