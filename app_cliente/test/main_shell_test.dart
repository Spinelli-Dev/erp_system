// Testes da navegação principal: verificação de login, troca de abas
// sem perder estado, badge do carrinho, deep link e logout.

import 'package:app_cliente/main.dart';
import 'package:app_cliente/navigation/app_router.dart';
import 'package:app_cliente/providers/auth_provider.dart';
import 'package:app_cliente/providers/cart_provider.dart';
import 'package:app_cliente/providers/navigation_provider.dart';
import 'package:app_cliente/providers/order_history_provider.dart';
import 'package:app_cliente/providers/product_provider.dart';
import 'package:app_cliente/screens/profile_screen.dart';
import 'package:app_cliente/models/date_filter.dart';
import 'package:app_cliente/models/product.dart';
import 'package:app_cliente/services/user_profile_service.dart';
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

Future<void> _entrar(WidgetTester tester) async {
  await tester.enterText(find.byType(TextFormField).at(0), 'cliente@teste.com');
  await tester.enterText(find.byType(TextFormField).at(1), '1234');
  await tester.ensureVisible(find.text('ENTRAR'));
  await tester.tap(find.text('ENTRAR'));
  await tester.pumpAndSettle();
}

/// Sessão já aberta, sem o atraso do serviço mockado (o Future.delayed dele
/// nunca termina fora do relógio falso do testWidgets).
Future<AuthProvider> _logado() async {
  final auth = AuthProvider(service: MockUserProfileService(atraso: Duration.zero));
  await auth.login('cliente@teste.com', '1234');
  return auth;
}

Finder _aba(String label) => find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

/// App com providers controlados pelo teste, para inspecionar o estado.
Widget _app({required AuthProvider auth, CartProvider? cart, String rotaInicial = '/produtos'}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: auth),
      ChangeNotifierProvider(create: (_) => NavigationProvider()),
      ChangeNotifierProvider(create: (_) => cart ?? CartProvider()),
      ChangeNotifierProvider(create: (_) => ProductProvider()),
      ChangeNotifierProvider(create: (_) => OrderHistoryProvider()),
    ],
    child: Builder(
      builder: (context) {
        final router = AppRouter(auth);
        return MaterialApp(
          initialRoute: rotaInicial,
          onGenerateInitialRoutes: router.gerarRotasIniciais,
          onGenerateRoute: router.gerarRota,
        );
      },
    ),
  );
}

void main() {
  testWidgets('Sem sessão, o app abre no login; ao entrar, mostra as abas', (tester) async {
    await tester.pumpWidget(const MaxiMassasApp());
    await tester.pumpAndSettle();

    expect(find.text('Acesse sua conta'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    await _entrar(tester);

    expect(find.byType(NavigationBar), findsOneWidget);
    for (final label in ['Produtos', 'Carrinho', 'Meus Pedidos', 'Perfil']) {
      expect(_aba(label), findsOneWidget);
    }
    expect(find.byType(BackButton), findsNothing);
  });

  testWidgets('Deep link para uma aba sem sessão passa pelo login e volta para a aba', (tester) async {
    await tester.pumpWidget(_app(auth: AuthProvider(), rotaInicial: '/pedidos'));
    await tester.pumpAndSettle();

    expect(find.text('Acesse sua conta'), findsOneWidget);

    await _entrar(tester);

    expect(find.text('Nenhum pedido ainda'), findsOneWidget);
  });

  testWidgets('Rota desconhecida cai na aba de produtos em vez de dar erro', (tester) async {
    final auth = await _logado();

    await tester.pumpWidget(_app(auth: auth, rotaInicial: '/nao-existe'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Maxi Massas'), findsOneWidget); // AppBar da aba Produtos
  });

  testWidgets('Troca de aba mantém o estado da aba anterior (filtro de categoria)', (tester) async {
    final auth = await _logado();

    await tester.pumpWidget(_app(auth: auth));
    await tester.pumpAndSettle();

    final provider = Provider.of<ProductProvider>(tester.element(find.byType(NavigationBar)), listen: false);
    final categoria = provider.categories[1];
    await tester.tap(find.text(categoria).first);
    await tester.pumpAndSettle();

    await tester.tap(_aba('Perfil'));
    await tester.pumpAndSettle();
    expect(find.text('Meu Perfil'), findsOneWidget);

    await tester.tap(_aba('Produtos'));
    await tester.pumpAndSettle();
    expect(provider.selectedCategory, categoria);
    expect(provider.status, ProductLoadStatus.loaded);
  });

  testWidgets('Badge do carrinho acompanha o CartProvider em tempo real', (tester) async {
    final auth = await _logado();
    final cart = CartProvider();

    await tester.pumpWidget(_app(auth: auth, cart: cart));
    await tester.pumpAndSettle();

    expect(find.descendant(of: find.byType(Badge), matching: find.text('3')), findsNothing);

    cart.addProduct(_produtoTeste, quantity: 3);
    await tester.pump();
    expect(find.descendant(of: find.byType(Badge), matching: find.text('3')), findsOneWidget);

    cart.clear();
    await tester.pump();
    expect(find.descendant(of: find.byType(Badge), matching: find.text('3')), findsNothing);
  });

  testWidgets('"Voltar aos produtos" no carrinho vazio troca de aba', (tester) async {
    final auth = await _logado();

    await tester.pumpWidget(_app(auth: auth, rotaInicial: '/carrinho'));
    await tester.pumpAndSettle();
    expect(find.text('Seu carrinho está vazio'), findsOneWidget);

    await tester.tap(find.text('VOLTAR AOS PRODUTOS'));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    final navegacao = Provider.of<NavigationProvider>(tester.element(find.byType(NavigationBar)), listen: false);
    expect(navegacao.abaAtual, AppTab.produtos);
  });

  testWidgets('Logout limpa o carrinho, encerra a sessão e volta ao login', (tester) async {
    final auth = await _logado();
    final cart = CartProvider()..addProduct(_produtoTeste);

    await tester.pumpWidget(_app(auth: auth, cart: cart));
    await tester.pumpAndSettle();

    await tester.tap(_aba('Perfil'));
    await tester.pumpAndSettle();
    expect(find.text('cliente@teste.com'), findsOneWidget);

    // Com os endereços salvos, o botão fica abaixo da dobra.
    await tester.scrollUntilVisible(
      find.text('SAIR DA CONTA'),
      200,
      scrollable: find.descendant(of: find.byType(ProfileScreen), matching: find.byType(Scrollable)).first,
    );
    await tester.tap(find.text('SAIR DA CONTA'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sair'));
    await tester.pumpAndSettle();

    expect(cart.isEmpty, isTrue);
    expect(auth.isLoggedIn, isFalse);
    expect(find.text('Acesse sua conta'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('Sair da aba Meus Pedidos volta o filtro de período ao padrão', (tester) async {
    final auth = await _logado();

    await tester.pumpWidget(_app(auth: auth, rotaInicial: '/pedidos'));
    await tester.pumpAndSettle();

    final historico = Provider.of<OrderHistoryProvider>(tester.element(find.byType(NavigationBar)), listen: false);
    historico.selecionarFiltro(DateFilter.all);

    await tester.tap(_aba('Produtos'));
    await tester.pumpAndSettle();

    expect(historico.filtro, DateFilter.last7Days);
  });
}
