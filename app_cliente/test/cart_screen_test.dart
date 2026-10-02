// Testes de widget da tela de carrinho: estado vazio, alterar
// quantidade (com loading simulado), remover item (com desfazer) e
// finalizar pedido.

import 'package:app_cliente/core/formatters.dart';
import 'package:app_cliente/models/product.dart';
import 'package:app_cliente/providers/auth_provider.dart';
import 'package:app_cliente/providers/cart_provider.dart';
import 'package:app_cliente/providers/order_history_provider.dart';
import 'package:app_cliente/providers/product_provider.dart';
import 'package:app_cliente/screens/cart_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

const _produtoTeste = Product(
  id: '1',
  name: 'Espaguete Tradicional',
  description: 'Massa fresca artesanal.',
  price: 24.90,
  category: 'Massas',
);

Widget _wrapComProviders(Widget child, {CartProvider? cartProvider}) {
  return MultiProvider(
    providers: [
      // O checkout (aberto por "Finalizar pedido") lê contato e endereços daqui.
      ChangeNotifierProvider(create: (_) => AuthProvider()),
      ChangeNotifierProvider(create: (_) => cartProvider ?? CartProvider()),
      ChangeNotifierProvider(create: (_) => ProductProvider()),
      ChangeNotifierProvider(create: (_) => OrderHistoryProvider()),
    ],
    // Empacota numa tela com botão voltar, já que CartScreen depende de
    // `Navigator.pop()` (ex.: "Voltar aos Produtos").
    child: MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => child)),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('Mostra estado vazio quando o carrinho não tem itens', (tester) async {
    await tester.pumpWidget(_wrapComProviders(const CartScreen()));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    expect(find.text('Seu carrinho está vazio'), findsOneWidget);
    expect(find.text('VOLTAR AOS PRODUTOS'), findsOneWidget);
  });

  testWidgets('Lista o item, calcula subtotal/total e mostra a taxa de entrega', (tester) async {
    final cart = CartProvider()..addProduct(_produtoTeste, quantity: 2);

    await tester.pumpWidget(_wrapComProviders(const CartScreen(), cartProvider: cart));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    expect(find.text('Espaguete Tradicional'), findsOneWidget);
    // Subtotal do item (2x 24,90) — aparece tanto no card do item quanto
    // na linha "Subtotal" do rodapé.
    expect(find.text(formatarPreco(49.80)), findsNWidgets(2));
    expect(find.text('Taxa de entrega'), findsOneWidget);
    // Total = subtotal (49,80) + taxa de entrega fixa (6,90).
    expect(find.text(formatarPreco(56.70)), findsOneWidget);
    expect(find.text('FINALIZAR PEDIDO'), findsOneWidget);
  });

  testWidgets('Aumentar quantidade mostra loading e depois atualiza o subtotal', (tester) async {
    final cart = CartProvider()..addProduct(_produtoTeste, quantity: 1);

    await tester.pumpWidget(_wrapComProviders(const CartScreen(), cartProvider: cart));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump(); // primeiro frame: entra em "processando"

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle(); // aguarda a "sincronização" simulada terminar

    expect(cart.quantityOf('1'), 2);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('Remover item pelo botão de lixeira mostra SnackBar com Desfazer', (tester) async {
    final cart = CartProvider()..addProduct(_produtoTeste);

    await tester.pumpWidget(_wrapComProviders(const CartScreen(), cartProvider: cart));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete_outline).first);
    await tester.pump();
    // Deixa a animação de entrada da SnackBar terminar antes de tocar
    // nela, senão o toque em "DESFAZER" não acerta o widget.
    await tester.pump(const Duration(milliseconds: 300));

    expect(cart.isEmpty, isTrue);
    expect(find.textContaining('removido do carrinho'), findsOneWidget);

    await tester.tap(find.text('DESFAZER'));
    await tester.pumpAndSettle();

    expect(cart.isEmpty, isFalse);
    expect(cart.quantityOf('1'), 1);
  });

  testWidgets('Diminuir com quantidade 1 não remove o item — botão "-" fica desabilitado', (tester) async {
    final cart = CartProvider()..addProduct(_produtoTeste, quantity: 1);

    await tester.pumpWidget(_wrapComProviders(const CartScreen(), cartProvider: cart));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    final botaoDiminuir = tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.remove));
    expect(botaoDiminuir.onPressed, isNull);

    // Mesmo tocando, um IconButton desabilitado não faz nada.
    await tester.tap(find.byIcon(Icons.remove));
    await tester.pumpAndSettle();

    expect(cart.isEmpty, isFalse);
    expect(cart.quantityOf('1'), 1);
  });

  testWidgets('Abrir o carrinho esconde a fila inteira de SnackBars de "produto adicionado"', (tester) async {
    final cart = CartProvider()..addProduct(_produtoTeste);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CartProvider>.value(value: cart),
          ChangeNotifierProvider(create: (_) => ProductProvider()),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    // Simula o usuário adicionando dois produtos rápido:
                    // a segunda SnackBar fica na fila do
                    // ScaffoldMessenger, atrás da primeira.
                    final messenger = ScaffoldMessenger.of(context);
                    messenger.showSnackBar(const SnackBar(content: Text('Produto A adicionado ao carrinho')));
                    messenger.showSnackBar(const SnackBar(content: Text('Produto B adicionado ao carrinho')));
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CartScreen()));
                  },
                  child: const Text('adicionar dois e abrir carrinho'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('adicionar dois e abrir carrinho'));
    await tester.pumpAndSettle();

    expect(find.textContaining('adicionado ao carrinho'), findsNothing);

    // Mesmo esperando o tempo que a 2ª SnackBar levaria para "vencer a
    // vez" caso a fila não tivesse sido limpa (só escondida a atual),
    // nada aparece.
    await tester.pump(const Duration(seconds: 5));
    expect(find.textContaining('adicionado ao carrinho'), findsNothing);
  });

  testWidgets('Finalizar pedido abre a tela de checkout (endereço/pagamento)', (tester) async {
    final cart = CartProvider()..addProduct(_produtoTeste);

    await tester.pumpWidget(_wrapComProviders(const CartScreen(), cartProvider: cart));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('FINALIZAR PEDIDO'));
    await tester.pumpAndSettle();

    expect(find.text('Finalizar Pedido'), findsOneWidget); // título da AppBar do checkout
    expect(find.text('Tipo de entrega'), findsOneWidget);
    // O carrinho continua intacto — só é limpo depois que o pedido é
    // realmente confirmado na tela de checkout.
    expect(cart.isEmpty, isFalse);
  });
}
