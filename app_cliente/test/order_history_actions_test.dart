// Testes do filtro por período e do "Repetir pedido" na aba Meus Pedidos.

import 'package:app_cliente/models/cart_item.dart';
import 'package:app_cliente/models/date_filter.dart';
import 'package:app_cliente/models/delivery_type.dart';
import 'package:app_cliente/models/order_confirmation.dart';
import 'package:app_cliente/models/payment_method.dart';
import 'package:app_cliente/models/product.dart';
import 'package:app_cliente/providers/cart_provider.dart';
import 'package:app_cliente/providers/order_history_provider.dart';
import 'package:app_cliente/providers/product_provider.dart';
import 'package:app_cliente/screens/order_history_screen.dart';
import 'package:app_cliente/services/franchise_service.dart';
import 'package:app_cliente/services/product_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

const _espaguete = Product(id: '1', name: 'Espaguete Tradicional', description: '', price: 24.90, category: 'Massas');
const _molho = Product(id: '2', name: 'Molho Bolonhesa', description: '', price: 18.90, category: 'Molhos');

final _agora = DateTime(2026, 9, 27, 18, 0);
DateTime _relogio() => _agora;

OrderConfirmation _pedido(String id, DateTime data, {List<CartItem>? itens}) {
  final listaItens = itens ?? [CartItem(product: _espaguete, quantity: 1)];
  final subtotal = listaItens.fold<double>(0, (soma, item) => soma + item.subtotal);
  return OrderConfirmation(
    orderId: id,
    orderDate: data,
    deliveryType: DeliveryType.pickup,
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

/// Cardápio sem atraso (o Future.delayed do mock não avança sozinho
/// dentro do relógio falso do testWidgets).
class _CardapioFixo implements ProductService {
  _CardapioFixo(this.produtos);
  final List<Product> produtos;

  @override
  Future<List<Product>> fetchProducts() async => produtos;
}

Widget _wrap(OrderHistoryProvider historico, {CartProvider? cart, List<Product> cardapio = const [_espaguete, _molho]}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: historico),
      ChangeNotifierProvider(create: (_) => cart ?? CartProvider()),
      ChangeNotifierProvider(create: (_) => ProductProvider(service: _CardapioFixo(cardapio))),
    ],
    child: const MaterialApp(home: OrderHistoryScreen()),
  );
}

void main() {
  group('DateFilter', () {
    test('Últimos 7 dias conta hoje e os 6 dias anteriores', () {
      expect(DateFilter.last7Days.inclui(DateTime(2026, 9, 21, 0, 0), agora: _agora), isTrue);
      expect(DateFilter.last7Days.inclui(DateTime(2026, 9, 20, 23, 59), agora: _agora), isFalse);
    });

    test('Este mês e últimos 3 meses', () {
      expect(DateFilter.thisMonth.inclui(DateTime(2026, 9, 1), agora: _agora), isTrue);
      expect(DateFilter.thisMonth.inclui(DateTime(2026, 8, 31), agora: _agora), isFalse);
      expect(DateFilter.last3Months.inclui(DateTime(2026, 6, 27), agora: _agora), isTrue);
      expect(DateFilter.last3Months.inclui(DateTime(2026, 6, 26), agora: _agora), isFalse);
      // Virada de ano: janeiro menos 3 meses cai em outubro do ano anterior.
      expect(DateFilter.last3Months.inclui(DateTime(2025, 10, 15), agora: DateTime(2026, 1, 15)), isTrue);
    });

    test('Personalizado inclui o dia final inteiro', () {
      final periodo = DateTimeRange(start: DateTime(2026, 9, 10), end: DateTime(2026, 9, 12));
      expect(DateFilter.custom.inclui(DateTime(2026, 9, 12, 23, 30), agora: _agora, periodo: periodo), isTrue);
      expect(DateFilter.custom.inclui(DateTime(2026, 9, 13), agora: _agora, periodo: periodo), isFalse);
      expect(DateFilter.custom.inclui(DateTime(2026, 9, 9, 23, 59), agora: _agora, periodo: periodo), isFalse);
    });
  });

  group('Filtro na tela', () {
    testWidgets('Abre em "Últimos 7 dias" e troca a lista ao selecionar outro filtro', (tester) async {
      final historico = OrderHistoryProvider(relogio: _relogio)
        ..adicionar(_pedido('#ANTIGO', DateTime(2026, 7, 10)))
        ..adicionar(_pedido('#DO-MES', DateTime(2026, 9, 5)))
        ..adicionar(_pedido('#RECENTE', DateTime(2026, 9, 26)));

      await tester.pumpWidget(_wrap(historico));
      await tester.pumpAndSettle();

      expect(historico.filtro, DateFilter.last7Days);
      expect(find.text('#RECENTE'), findsOneWidget);
      expect(find.text('#DO-MES'), findsNothing);

      await tester.tap(find.text('Este mês'));
      await tester.pumpAndSettle();
      expect(find.text('#DO-MES'), findsOneWidget);
      expect(find.text('#ANTIGO'), findsNothing);

      await tester.tap(find.text('Todos'));
      await tester.pumpAndSettle();
      expect(find.text('#ANTIGO'), findsOneWidget);
    });

    testWidgets('Período sem pedidos mostra aviso com atalho para "Todos"', (tester) async {
      final historico = OrderHistoryProvider(relogio: _relogio)..adicionar(_pedido('#ANTIGO', DateTime(2026, 7, 10)));

      await tester.pumpWidget(_wrap(historico));
      await tester.pumpAndSettle();

      expect(find.text('Nenhum pedido neste período'), findsOneWidget);

      await tester.tap(find.text('Ver todos os pedidos'));
      await tester.pumpAndSettle();

      expect(historico.filtro, DateFilter.all);
      expect(find.text('#ANTIGO'), findsOneWidget);
    });

    test('resetarFiltro e limpar voltam ao filtro padrão', () {
      final historico = OrderHistoryProvider(relogio: _relogio)..selecionarFiltro(DateFilter.all);
      historico.resetarFiltro();
      expect(historico.filtro, DateFilter.last7Days);

      historico.selecionarPeriodo(DateTimeRange(start: DateTime(2026, 9, 1), end: DateTime(2026, 9, 2)));
      historico.limpar();
      expect(historico.filtro, DateFilter.last7Days);
      expect(historico.periodoPersonalizado, isNull);
    });
  });

  group('Repetir pedido', () {
    test('Usa o preço atual do cardápio e soma com o que já está no carrinho', () {
      const espagueteMaisCaro = Product(id: '1', name: 'Espaguete Tradicional', description: '', price: 29.90, category: 'Massas');
      final cart = CartProvider()..addProduct(espagueteMaisCaro);

      final resultado = cart.repetirItens([CartItem(product: _espaguete, quantity: 2)], [espagueteMaisCaro]);

      expect(resultado.unidadesAdicionadas, 2);
      expect(cart.quantityOf('1'), 3);
      expect(cart.items.single.product.price, 29.90);
    });

    testWidgets('Adiciona todos os itens e confirma com SnackBar', (tester) async {
      final cart = CartProvider();
      final historico = OrderHistoryProvider(relogio: _relogio)
        ..adicionar(_pedido('#MM1', DateTime(2026, 9, 26), itens: [
          CartItem(product: _espaguete, quantity: 2),
          CartItem(product: _molho, quantity: 1),
        ]));

      await tester.pumpWidget(_wrap(historico, cart: cart));
      await tester.pumpAndSettle();

      await tester.tap(find.text('REPETIR PEDIDO'));
      await tester.pumpAndSettle();

      expect(cart.totalItems, 3);
      expect(find.text('3 itens adicionados ao carrinho'), findsOneWidget);
      expect(find.text('VER CARRINHO'), findsOneWidget);
    });

    testWidgets('Avisa quais itens estão indisponíveis e adiciona o resto', (tester) async {
      final cart = CartProvider();
      final historico = OrderHistoryProvider(relogio: _relogio)
        ..adicionar(_pedido('#MM1', DateTime(2026, 9, 26), itens: [
          CartItem(product: _espaguete, quantity: 2),
          CartItem(product: _molho, quantity: 1),
        ]));
      // Molho esgotado; o espaguete continua no cardápio.
      const molhoEsgotado = Product(id: '2', name: 'Molho Bolonhesa', description: '', price: 18.90, category: 'Molhos', isAvailable: false);

      await tester.pumpWidget(_wrap(historico, cart: cart, cardapio: const [_espaguete, molhoEsgotado]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('REPETIR PEDIDO'));
      await tester.pumpAndSettle();

      expect(cart.quantityOf('1'), 2);
      expect(cart.quantityOf('2'), 0);
      expect(find.text('Alguns itens estão indisponíveis'), findsOneWidget);
      expect(find.text('Molho Bolonhesa'), findsOneWidget);

      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      expect(find.text('Alguns itens estão indisponíveis'), findsNothing);
    });

    testWidgets('Nenhum item disponível: não mexe no carrinho', (tester) async {
      final cart = CartProvider();
      final historico = OrderHistoryProvider(relogio: _relogio)
        ..adicionar(_pedido('#MM1', DateTime(2026, 9, 26)));

      // Espaguete saiu do cardápio.
      await tester.pumpWidget(_wrap(historico, cart: cart, cardapio: const [_molho]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('REPETIR PEDIDO'));
      await tester.pumpAndSettle();

      expect(cart.isEmpty, isTrue);
      expect(find.text('Itens indisponíveis'), findsOneWidget);
      expect(find.text('Entendi'), findsOneWidget);
    });
  });
}
