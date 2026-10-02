// Testes do estoque atualizado: o estoque muda fora do app (balcão, painel,
// outros clientes), então o app busca o cardápio de novo e ajusta o
// carrinho e o detalhe do produto ao saldo atual — o caso de "o app deixou
// pôr 10 pizzas quando só restavam 8".

import 'package:app_cliente/models/product.dart';
import 'package:app_cliente/navigation/atualizar_cardapio.dart';
import 'package:app_cliente/providers/cart_provider.dart';
import 'package:app_cliente/providers/navigation_provider.dart';
import 'package:app_cliente/providers/product_provider.dart';
import 'package:app_cliente/screens/product_detail_screen.dart';
import 'package:app_cliente/services/product_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

Product _pizza(int estoque, {double preco = 45, bool disponivel = true}) => Product(
      id: '1004',
      name: 'Pizza Calabresa',
      description: '',
      price: preco,
      category: 'Pizzas',
      stock: estoque,
      isAvailable: disponivel,
    );

const _molho = Product(id: '2', name: 'Molho Branco', description: '', price: 5.9, category: 'Molhos', stock: 4);

/// Cardápio "do servidor" que o teste muda entre uma busca e outra.
class _CardapioFalso implements ProductService {
  _CardapioFalso(this.produtos);

  List<Product> produtos;
  bool falhar = false;

  @override
  Future<List<Product>> fetchProducts() async {
    if (falhar) throw Exception('sem conexão');
    return produtos;
  }
}

void main() {
  group('CartProvider.sincronizarComCardapio', () {
    test('reduz ao estoque atual, troca o preço e avisa o que mudou', () {
      final cart = CartProvider()
        ..addProduct(_pizza(10), quantity: 10)
        ..addProduct(_molho, quantity: 2);

      final ajustes = cart.sincronizarComCardapio([_pizza(8, preco: 47), _molho]);

      expect(cart.quantityOf('1004'), 8);
      expect(cart.items.firstWhere((i) => i.product.id == '1004').product.price, 47);
      expect(cart.restanteEmEstoque(_pizza(8)), 0, reason: 'o "+" trava no novo saldo');
      expect(cart.quantityOf('2'), 2);
      expect(ajustes, ['Pizza Calabresa: só restam 8 unidades']);
    });

    test('tira do carrinho o que esgotou, ficou indisponível ou saiu do cardápio', () {
      final cart = CartProvider()
        ..addProduct(_pizza(10), quantity: 2)
        ..addProduct(_molho);

      final ajustes = cart.sincronizarComCardapio([_pizza(0)]);

      expect(cart.isEmpty, isTrue);
      expect(ajustes, ['Pizza Calabresa esgotou e saiu do carrinho', 'Molho Branco esgotou e saiu do carrinho']);
      expect(CartProvider().sincronizarComCardapio([_pizza(5)]), isEmpty, reason: 'carrinho vazio: nada a avisar');
    });
  });

  group('ProductProvider.atualizar', () {
    test('troca o estoque sem voltar a "carregando" e mantém a lista se falhar', () async {
      final servidor = _CardapioFalso([_pizza(10)]);
      final produtos = ProductProvider(service: servidor);
      await produtos.garantirCarregado();

      servidor.produtos = [_pizza(8)];
      final estados = <ProductLoadStatus>[];
      produtos.addListener(() => estados.add(produtos.status));
      expect(await produtos.atualizar(), isTrue);
      expect(produtos.produtoAtual('1004')?.stock, 8);
      expect(estados, everyElement(ProductLoadStatus.loaded));

      servidor.falhar = true;
      expect(await produtos.atualizar(), isFalse);
      expect(produtos.produtoAtual('1004')?.stock, 8, reason: 'sem conexão, fica o último saldo conhecido');
    });
  });

  testWidgets('atualizar ajusta o carrinho e mostra o aviso ao cliente', (tester) async {
    final servidor = _CardapioFalso([_pizza(10)]);
    final produtos = ProductProvider(service: servidor);
    final cart = CartProvider()..addProduct(_pizza(10), quantity: 10);

    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: produtos),
        ChangeNotifierProvider.value(value: cart),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) =>
                TextButton(onPressed: () => atualizarCardapioECarrinho(context), child: const Text('atualizar')),
          ),
        ),
      ),
    ));
    await tester.pump();

    // Venda de 2 pizzas no balcão: o servidor passa a ter 8.
    servidor.produtos = [_pizza(8)];
    await tester.tap(find.text('atualizar'));
    await tester.pump();
    await tester.pump();

    expect(cart.quantityOf('1004'), 8);
    expect(find.textContaining('Pizza Calabresa: só restam 8 unidades'), findsOneWidget);
  });

  testWidgets('detalhe do produto segue o estoque atual, não o de quando abriu', (tester) async {
    final servidor = _CardapioFalso([_pizza(3)]);
    final produtos = ProductProvider(service: servidor);
    await produtos.garantirCarregado();

    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: produtos),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
      ],
      child: MaterialApp(home: Scaffold(body: ProductDetailScreen(product: _pizza(3)))),
    ));

    // Enquanto a tela está aberta, vendem 2 no balcão: sobra 1.
    servidor.produtos = [_pizza(1)];
    await produtos.atualizar();
    await tester.pump();

    final mais = tester.widget<IconButton>(
      find.ancestor(of: find.byIcon(Icons.add), matching: find.byType(IconButton)).last,
    );
    expect(mais.onPressed, isNull, reason: 'com 1 em estoque, o seletor já está no máximo');
  });
}
