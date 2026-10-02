// Testes de widget da tela de confirmação de pedido: conteúdo das
// seções (tempo estimado, entrega/retirada, itens, valores, pagamento,
// observações) e navegação dos botões de ação.

import 'package:app_cliente/core/formatters.dart';
import 'package:app_cliente/core/payment_instructions.dart';
import 'package:app_cliente/models/address.dart';
import 'package:app_cliente/models/cart_item.dart';
import 'package:app_cliente/models/delivery_type.dart';
import 'package:app_cliente/models/order_confirmation.dart';
import 'package:app_cliente/models/payment_method.dart';
import 'package:app_cliente/models/product.dart';
import 'package:app_cliente/providers/cart_provider.dart';
import 'package:app_cliente/providers/order_history_provider.dart';
import 'package:app_cliente/providers/product_provider.dart';
import 'package:app_cliente/screens/order_confirmation_screen.dart';
import 'package:app_cliente/screens/order_history_screen.dart';
import 'package:app_cliente/services/franchise_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

const _produto = Product(
  id: '1',
  name: 'Espaguete Tradicional',
  description: 'Massa fresca artesanal.',
  price: 24.90,
  category: 'Massas',
);

OrderConfirmation _pedidoDeEntrega({double desconto = 0}) {
  const endereco = Address(street: 'Rua das Flores', number: '100', neighborhood: 'Centro');
  final itens = [CartItem(product: _produto, quantity: 2)];
  const total0 = 49.80 + 6.90;
  final total = total0 - desconto;
  return OrderConfirmation(
    orderId: '#MM000123',
    orderDate: DateTime(2026, 9, 21, 14, 32),
    deliveryType: DeliveryType.delivery,
    deliveryAddress: endereco,
    pickupLocation: franquiaPadrao,
    items: itens,
    paymentMethod: PaymentMethod.pix,
    subtotal: 49.80,
    deliveryFee: 6.90,
    discount: desconto,
    total: total,
    specialObservations: 'Deixar na portaria',
    estimatedTimeMinutes: franquiaPadrao.tempoEntregaMinutos,
    paymentInstructions: gerarInstrucoesPagamento(
      method: PaymentMethod.pix,
      total: total,
      franquia: franquiaPadrao,
    ),
  );
}

OrderConfirmation _pedidoDeRetirada() {
  final itens = [CartItem(product: _produto, quantity: 1)];
  return OrderConfirmation(
    orderId: '#MM000456',
    orderDate: DateTime(2026, 9, 21, 18, 0),
    deliveryType: DeliveryType.pickup,
    pickupLocation: franquiaPadrao,
    items: itens,
    paymentMethod: PaymentMethod.cash,
    subtotal: 24.90,
    deliveryFee: 0,
    total: 24.90,
    estimatedTimeMinutes: franquiaPadrao.tempoPreparoMinutos,
    paymentInstructions: gerarInstrucoesPagamento(
      method: PaymentMethod.cash,
      total: 24.90,
      franquia: franquiaPadrao,
    ),
  );
}

Widget _wrap(OrderConfirmation pedido) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => CartProvider()),
      ChangeNotifierProvider(create: (_) => ProductProvider()),
      ChangeNotifierProvider(create: (_) => OrderHistoryProvider()),
    ],
    child: MaterialApp(
      routes: {
        '/produtos': (_) => const Scaffold(body: Text('TELA DE PRODUTOS')),
        '/pedidos': (_) => const OrderHistoryScreen(),
      },
      home: OrderConfirmationScreen(pedido: pedido),
    ),
  );
}

void main() {
  testWidgets('Mostra número do pedido, mensagem de sucesso e sem botão de voltar', (tester) async {
    await tester.pumpWidget(_wrap(_pedidoDeEntrega()));
    await tester.pumpAndSettle();

    expect(find.text('Pedido Confirmado'), findsOneWidget); // título da AppBar
    expect(find.text('Seu pedido foi recebido!'), findsOneWidget);
    expect(find.text('#MM000123'), findsOneWidget);
    expect(find.byType(BackButton), findsNothing);
  });

  testWidgets('Entrega mostra endereço e mensagem de chegada; retirada mostra a loja e o horário', (tester) async {
    await tester.pumpWidget(_wrap(_pedidoDeEntrega()));
    await tester.pumpAndSettle();

    expect(find.textContaining('Rua das Flores, 100'), findsOneWidget);
    expect(find.textContaining('chegará em aproximadamente'), findsOneWidget);
    expect(find.text('Editar endereço'), findsOneWidget);

    await tester.pumpWidget(_wrap(_pedidoDeRetirada()));
    await tester.pumpAndSettle();

    expect(find.textContaining(franquiaPadrao.address), findsOneWidget);
    expect(find.textContaining('estará pronta em'), findsOneWidget);
    expect(find.text('Editar endereço'), findsNothing); // não faz sentido para retirada
  });

  testWidgets('Toque em "Editar endereço" explica que não dá para editar aqui', (tester) async {
    await tester.pumpWidget(_wrap(_pedidoDeEntrega()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Editar endereço'));
    await tester.pumpAndSettle();

    expect(find.text('Pedido já confirmado'), findsOneWidget);
    expect(find.textContaining(franquiaPadrao.phoneNumber), findsWidgets);
  });

  testWidgets('Lista os itens e os valores, com desconto só quando maior que zero', (tester) async {
    await tester.pumpWidget(_wrap(_pedidoDeEntrega()));
    await tester.pumpAndSettle();

    expect(find.textContaining('Espaguete Tradicional'), findsOneWidget);
    expect(find.text('Taxa de entrega'), findsOneWidget);
    expect(find.text('Desconto'), findsNothing);
    expect(find.text(formatarPreco(56.70)), findsOneWidget); // total

    await tester.pumpWidget(_wrap(_pedidoDeEntrega(desconto: 5)));
    await tester.pumpAndSettle();

    expect(find.text('Desconto'), findsOneWidget);
  });

  testWidgets('Mostra instruções específicas da forma de pagamento e as observações', (tester) async {
    await tester.pumpWidget(_wrap(_pedidoDeEntrega()));
    await tester.pumpAndSettle();

    expect(find.textContaining('Chave Pix'), findsOneWidget);
    expect(find.text('Deixar na portaria'), findsOneWidget);

    await tester.pumpWidget(_wrap(_pedidoDeRetirada()));
    await tester.pumpAndSettle();

    expect(find.textContaining('em dinheiro'), findsOneWidget);
    expect(find.text('Observações'), findsNothing); // pedido de retirada não tem observação
  });

  testWidgets('"Fazer Novo Pedido" navega para a tela de produtos', (tester) async {
    await tester.pumpWidget(_wrap(_pedidoDeEntrega()));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('FAZER NOVO PEDIDO'));
    await tester.tap(find.text('FAZER NOVO PEDIDO'));
    await tester.pumpAndSettle();

    expect(find.text('TELA DE PRODUTOS'), findsOneWidget);
    expect(find.text('Pedido Confirmado'), findsNothing);
  });

  testWidgets('"Ver Meus Pedidos" abre o histórico', (tester) async {
    await tester.pumpWidget(_wrap(_pedidoDeEntrega()));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('VER MEUS PEDIDOS'));
    await tester.tap(find.text('VER MEUS PEDIDOS'));
    await tester.pumpAndSettle();

    expect(find.text('Meus Pedidos'), findsOneWidget);
  });
}
