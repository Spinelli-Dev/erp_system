// Testes de widget da tela "Meus Pedidos": estado vazio, listagem dos
// pedidos já confirmados na sessão e os detalhes do card expandido
// (itens, endereço de entrega, contato pelo WhatsApp).

import 'package:app_cliente/models/address.dart';
import 'package:app_cliente/models/cart_item.dart';
import 'package:app_cliente/models/delivery_type.dart';
import 'package:app_cliente/models/order_confirmation.dart';
import 'package:app_cliente/models/payment_method.dart';
import 'package:app_cliente/models/product.dart';
import 'package:app_cliente/providers/order_history_provider.dart';
import 'package:app_cliente/screens/order_history_screen.dart';
import 'package:app_cliente/services/franchise_service.dart';
import 'package:app_cliente/services/whatsapp_service.dart';
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

const _produto2 = Product(
  id: '2',
  name: 'Molho Bolonhesa',
  description: 'Molho de carne moída.',
  price: 18.90,
  category: 'Molhos',
);

const _enderecoEntrega = Address(
  street: 'Avenida Florência',
  number: '455',
  complement: 'Casa 2',
  neighborhood: 'Centro',
  zipCode: '15900-020',
);

OrderConfirmation _pedido(String id, {DateTime? data, List<CartItem>? itens, Address? entregarEm}) {
  final listaItens = itens ?? [CartItem(product: _produto, quantity: 1)];
  final subtotal = listaItens.fold<double>(0, (soma, item) => soma + item.subtotal);
  return OrderConfirmation(
    orderId: id,
    orderDate: data ?? DateTime(2026, 9, 21, 12, 0),
    deliveryType: entregarEm == null ? DeliveryType.pickup : DeliveryType.delivery,
    deliveryAddress: entregarEm,
    pickupLocation: franquiaPadrao,
    items: listaItens,
    paymentMethod: PaymentMethod.card,
    subtotal: subtotal,
    deliveryFee: 0,
    total: subtotal,
    estimatedTimeMinutes: 30,
    paymentInstructions: '',
  );
}

/// "Agora" fixo: os pedidos de teste (20 e 21/09/2026) ficam dentro do
/// filtro padrão (últimos 7 dias) independente do dia em que o teste roda.
DateTime _hoje() => DateTime(2026, 9, 22, 9, 0);

Widget _wrap(OrderHistoryProvider historico) {
  return ChangeNotifierProvider.value(
    value: historico,
    child: const MaterialApp(home: OrderHistoryScreen()),
  );
}

void main() {
  testWidgets('Mostra estado vazio sem pedidos', (tester) async {
    await tester.pumpWidget(_wrap(OrderHistoryProvider(relogio: _hoje)));
    await tester.pumpAndSettle();

    expect(find.text('Nenhum pedido ainda'), findsOneWidget);
  });

  testWidgets('Lista os pedidos, mais recente primeiro', (tester) async {
    final historico = OrderHistoryProvider(relogio: _hoje)
      ..adicionar(_pedido('#MM000001', data: DateTime(2026, 9, 20, 10, 0)))
      ..adicionar(_pedido('#MM000002', data: DateTime(2026, 9, 21, 15, 0)));

    await tester.pumpWidget(_wrap(historico));
    await tester.pumpAndSettle();

    expect(find.text('#MM000001'), findsOneWidget);
    expect(find.text('#MM000002'), findsOneWidget);

    // O mais recente (#MM000002) aparece primeiro na lista.
    final posicao1 = tester.getTopLeft(find.text('#MM000002')).dy;
    final posicao2 = tester.getTopLeft(find.text('#MM000001')).dy;
    expect(posicao1, lessThan(posicao2));
  });

  testWidgets('Tocar no card expande a lista de produtos, e tocar de novo recolhe', (tester) async {
    final historico = OrderHistoryProvider(relogio: _hoje)
      ..adicionar(_pedido(
        '#MM000001',
        itens: [
          CartItem(product: _produto, quantity: 2),
          CartItem(product: _produto2, quantity: 1),
        ],
      ));

    await tester.pumpWidget(_wrap(historico));
    await tester.pumpAndSettle();

    // Antes de tocar, a lista de produtos não está visível.
    expect(find.text('Molho Bolonhesa'), findsNothing);

    await tester.tap(find.text('#MM000001'));
    await tester.pumpAndSettle();

    expect(find.text('Espaguete Tradicional'), findsOneWidget);
    expect(find.text('Molho Bolonhesa'), findsOneWidget);

    await tester.tap(find.text('#MM000001'));
    await tester.pumpAndSettle();

    expect(find.text('Molho Bolonhesa'), findsNothing);
  });
  group('Detalhes do pedido expandido', () {
    tearDown(() => WhatsAppService.abrirLink = (uri) async => false);

    testWidgets('Mostra o endereço de entrega usado no pedido', (tester) async {
      final historico = OrderHistoryProvider(relogio: _hoje)
        ..adicionar(_pedido('#MM000001', entregarEm: _enderecoEntrega));

      await tester.pumpWidget(_wrap(historico));
      await tester.pumpAndSettle();

      expect(find.text('Avenida Florência, 455 - Casa 2'), findsNothing);

      await tester.tap(find.text('#MM000001'));
      await tester.pumpAndSettle();

      expect(find.text('ENDEREÇO DE ENTREGA'), findsOneWidget);
      expect(find.text('Avenida Florência, 455 - Casa 2'), findsOneWidget);
      expect(find.text('Centro • CEP 15900-020'), findsOneWidget);
    });

    testWidgets('Na retirada, mostra a loja em vez de um endereço de entrega', (tester) async {
      final historico = OrderHistoryProvider(relogio: _hoje)..adicionar(_pedido('#MM000001'));

      await tester.pumpWidget(_wrap(historico));
      await tester.pumpAndSettle();
      await tester.tap(find.text('#MM000001'));
      await tester.pumpAndSettle();

      expect(find.text('RETIRADA NO LOCAL'), findsOneWidget);
      expect(find.text(franquiaPadrao.address), findsOneWidget);
      expect(find.text('ENDEREÇO DE ENTREGA'), findsNothing);
    });

    testWidgets('Botão do WhatsApp abre a conversa com a loja citando o pedido', (tester) async {
      Uri? aberto;
      WhatsAppService.abrirLink = (uri) async {
        aberto = uri;
        return true;
      };
      final historico = OrderHistoryProvider(relogio: _hoje)
        ..adicionar(_pedido('#MM000001', entregarEm: _enderecoEntrega));

      await tester.pumpWidget(_wrap(historico));
      await tester.pumpAndSettle();
      await tester.tap(find.text('#MM000001'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('FALAR COM A LOJA NO WHATSAPP'));
      await tester.tap(find.text('FALAR COM A LOJA NO WHATSAPP'));
      await tester.pumpAndSettle();

      expect(aberto, isNotNull);
      expect(aberto!.host, 'wa.me');
      expect(aberto!.path, '/5516999990000');
      expect(aberto!.queryParameters['text'], contains('#MM000001'));
    });

    testWidgets('Se o WhatsApp não abrir, mostra o telefone da loja', (tester) async {
      WhatsAppService.abrirLink = (uri) async => false;
      final historico = OrderHistoryProvider(relogio: _hoje)..adicionar(_pedido('#MM000001'));

      await tester.pumpWidget(_wrap(historico));
      await tester.pumpAndSettle();
      await tester.tap(find.text('#MM000001'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('FALAR COM A LOJA NO WHATSAPP'));
      await tester.tap(find.text('FALAR COM A LOJA NO WHATSAPP'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Fale com a loja pelo ${franquiaPadrao.phoneNumber}'), findsOneWidget);
    });

    test('Link do WhatsApp inclui o código do Brasil só quando falta', () {
      expect(WhatsAppService.montarLink('(16) 99999-0000', 'oi').path, '/5516999990000');
      expect(WhatsAppService.montarLink('+55 16 99999-0000', 'oi').path, '/5516999990000');
    });
  });
}
