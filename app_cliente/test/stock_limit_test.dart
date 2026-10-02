// Testes da trava de estoque: o cliente não consegue colocar no carrinho
// mais unidades do que o produto tem em estoque — nem pelo "+" do
// cardápio, nem pelo detalhe do produto, nem pelo carrinho, nem ao
// repetir um pedido. O "+" travado fica cinza e explica o motivo.

import 'package:app_cliente/models/cart_item.dart';
import 'package:app_cliente/models/product.dart';
import 'package:app_cliente/providers/cart_provider.dart';
import 'package:app_cliente/providers/navigation_provider.dart';
import 'package:app_cliente/screens/cart_screen.dart';
import 'package:app_cliente/screens/product_detail_screen.dart';
import 'package:app_cliente/widgets/product_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

const _canelone = Product(id: '1', name: 'Canelone 4 Queijos', description: '', price: 39.90, category: 'Massas', stock: 3);
const _semLimite = Product(id: '2', name: 'Espaguete', description: '', price: 24.90, category: 'Massas');

Widget _comCarrinho(CartProvider cart, Widget child) => MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: cart),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
      ],
      child: MaterialApp(home: Scaffold(body: child)),
    );

/// Botão "+" do seletor de quantidade (o último ícone de adicionar).
IconButton _botaoMais(WidgetTester tester) =>
    tester.widget<IconButton>(find.ancestor(of: find.byIcon(Icons.add), matching: find.byType(IconButton)).last);

void main() {
  group('CartProvider', () {
    test('adiciona só até o estoque e informa quanto entrou', () {
      final cart = CartProvider();

      expect(cart.addProduct(_canelone, quantity: 2), 2);
      expect(cart.restanteEmEstoque(_canelone), 1);
      expect(cart.addProduct(_canelone, quantity: 5), 1, reason: 'só cabia mais 1');
      expect(cart.quantityOf('1'), 3);
      expect(cart.atingiuLimite(_canelone), isTrue);
      expect(cart.addProduct(_canelone), 0);
      expect(cart.quantityOf('1'), 3);
    });

    test('produto sem estoque conhecido (mock) não tem limite', () {
      final cart = CartProvider();

      expect(cart.addProduct(_semLimite, quantity: 50), 50);
      expect(cart.atingiuLimite(_semLimite), isFalse);
    });

    test('alterar a quantidade no carrinho não passa do estoque', () async {
      final cart = CartProvider()..addProduct(_canelone, quantity: 3);

      await cart.updateQuantity('1', 4);
      expect(cart.quantityOf('1'), 3);

      await cart.updateQuantity('1', 2);
      expect(cart.quantityOf('1'), 2);
    });

    test('repetir pedido limita ao estoque atual e avisa o que entrou só em parte', () {
      final cart = CartProvider();
      final pedidoAntigo = [CartItem(product: _canelone, quantity: 5)];

      final resultado = cart.repetirItens(pedidoAntigo, const [_canelone]);

      expect(cart.quantityOf('1'), 3);
      expect(resultado.unidadesAdicionadas, 3);
      expect(resultado.indisponiveis.single, contains('só 3 de 5'));
    });
  });

  group('Telas', () {
    testWidgets('carrinho: "+" trava no estoque e mostra o aviso ao tocar', (tester) async {
      final cart = CartProvider()..addProduct(_canelone, quantity: 2);
      await tester.pumpWidget(_comCarrinho(cart, const CartScreen()));

      expect(_botaoMais(tester).onPressed, isNotNull, reason: '2 de 3: ainda pode subir');

      await tester.tap(find.byIcon(Icons.add).last);
      await tester.pumpAndSettle();
      expect(cart.quantityOf('1'), 3);
      expect(_botaoMais(tester).onPressed, isNull, reason: 'chegou ao estoque');

      await tester.tap(find.byIcon(Icons.add).last);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text(CartProvider.mensagemLimiteEstoque), findsOneWidget);
      expect(cart.quantityOf('1'), 3);
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('detalhe do produto: seletor para no estoque menos o que já está no carrinho', (tester) async {
      final cart = CartProvider()..addProduct(_canelone);
      await tester.pumpWidget(_comCarrinho(cart, const ProductDetailScreen(product: _canelone)));

      // Estoque 3, já tem 1 no carrinho: o seletor vai até 2.
      await tester.tap(find.byIcon(Icons.add).last);
      await tester.pump();
      expect(find.text('2'), findsOneWidget);
      expect(_botaoMais(tester).onPressed, isNull);
    });

    testWidgets('detalhe do produto: com todo o estoque no carrinho, o botão desabilita', (tester) async {
      final cart = CartProvider()..addProduct(_canelone, quantity: 3);
      await tester.pumpWidget(_comCarrinho(cart, const ProductDetailScreen(product: _canelone)));

      expect(find.text('ESTOQUE JÁ NO CARRINHO'), findsOneWidget);
      expect(_botaoMais(tester).onPressed, isNull);
    });

    testWidgets('cardápio: "+" do cartão fica travado e explica ao tocar', (tester) async {
      final cart = CartProvider()..addProduct(_canelone, quantity: 3);
      await tester.pumpWidget(_comCarrinho(
        cart,
        SizedBox(width: 200, height: 320, child: ProductCard(product: _canelone, onTap: () {})),
      ));

      await tester.tap(find.byIcon(Icons.add));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text(CartProvider.mensagemLimiteEstoque), findsOneWidget);
      expect(cart.quantityOf('1'), 3);
      await tester.pump(const Duration(seconds: 3));
    });
  });
}
