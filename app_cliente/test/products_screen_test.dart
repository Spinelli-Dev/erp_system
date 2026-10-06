// Testes de widget da tela de produtos: cobrem o estado de carregamento
// (skeleton), o filtro por categoria e o fluxo de adicionar ao carrinho
// (feedback visual). O badge do carrinho fica na barra inferior e é
// testado em main_shell_test.dart.

import 'package:app_cliente/providers/cart_provider.dart';
import 'package:app_cliente/providers/product_provider.dart';
import 'package:app_cliente/screens/products_screen.dart';
import 'package:app_cliente/widgets/product_card_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

Widget _wrapComProviders(Widget child) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => CartProvider()),
      ChangeNotifierProvider(create: (_) => ProductProvider()),
    ],
    child: MaterialApp(home: child),
  );
}

void main() {
  testWidgets('Mostra skeletons enquanto carrega e depois o grid de produtos', (tester) async {
    await tester.pumpWidget(_wrapComProviders(const ProductsScreen()));

    // Logo após o primeiro frame, o cardápio ainda está "carregando".
    expect(find.byType(ProductCardSkeleton), findsWidgets);

    // Aguarda a simulação de chamada de API (MockProductService) terminar.
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.byType(ProductCardSkeleton), findsNothing);
    expect(find.text('Espaguete Tradicional'), findsOneWidget);
    expect(find.text('Massas'), findsWidgets); // chip de categoria
  });

  testWidgets('Filtrar por categoria atualiza o grid dinamicamente', (tester) async {
    await tester.pumpWidget(_wrapComProviders(const ProductsScreen()));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // O grid completo (12 produtos, 2 colunas) é mais alto que a viewport
    // de teste, então o primeiro produto é o único garantido como visível
    // sem rolar — confirma que o estado inicial é "Todas as categorias".
    expect(find.text('Espaguete Tradicional'), findsOneWidget);

    await tester.tap(find.text('Bebidas'));
    await tester.pumpAndSettle();

    // Depois do filtro, só os 2 produtos de "Bebidas" existem no grid —
    // ambos cabem na viewport, então dá para afirmar presença e ausência.
    expect(find.text('Suco Natural'), findsOneWidget);
    expect(find.text('Refrigerante Lata'), findsOneWidget);
    expect(find.text('Espaguete Tradicional'), findsNothing);
  });

  testWidgets('Adicionar produto mostra feedback e coloca o item no carrinho', (tester) async {
    await tester.pumpWidget(_wrapComProviders(const ProductsScreen()));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    final botaoAdicionar = find.byIcon(Icons.add).first;
    await tester.ensureVisible(botaoAdicionar);
    await tester.tap(botaoAdicionar);
    await tester.pump();

    // Feedback só no botão (vira "check"), sem SnackBar cobrindo a tela.
    expect(find.byIcon(Icons.check), findsOneWidget);
    expect(find.textContaining('adicionado ao carrinho'), findsNothing);

    final cart = Provider.of<CartProvider>(tester.element(find.byType(ProductsScreen)), listen: false);
    expect(cart.totalItems, 1);

    // O botão volta de "check" para "+" após ~900ms — avança o tempo para
    // não deixar esse timer pendente ao final do teste.
    await tester.pump(const Duration(milliseconds: 1000));
  });
}
