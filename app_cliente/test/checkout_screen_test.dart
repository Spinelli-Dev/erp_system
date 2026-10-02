// Testes de widget da tela de finalização de pedido: alternância do tipo
// de entrega, validação de endereço obrigatório, seleção de forma de
// pagamento, endereço principal pré-preenchido / endereços salvos, taxa
// de entrega condicional e o fluxo de confirmação.

import 'package:app_cliente/models/address.dart';
import 'package:app_cliente/models/order_request.dart';
import 'package:app_cliente/models/product.dart';
import 'package:app_cliente/models/user_profile.dart';
import 'package:app_cliente/providers/auth_provider.dart';
import 'package:app_cliente/providers/cart_provider.dart';
import 'package:app_cliente/providers/order_history_provider.dart';
import 'package:app_cliente/providers/product_provider.dart';
import 'package:app_cliente/screens/checkout_screen.dart';
import 'package:app_cliente/services/order_service.dart';
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

const _principal = Address(
  id: 'e1',
  street: 'Rua das Palmeiras',
  number: '120',
  neighborhood: 'Jardim Itápolis',
  zipCode: '14900-000',
  city: 'Itápolis',
  state: 'SP',
  isMain: true,
);

const _outro = Address(
  id: 'e2',
  street: 'Avenida Florência',
  number: '455',
  neighborhood: 'Centro',
  zipCode: '14900-020',
  city: 'Itápolis',
  state: 'SP',
);

/// Sessão já aberta, com os [enderecos] salvos no perfil. O serviço não
/// tem latência (um Future.delayed não avança fora do relógio falso).
Future<AuthProvider> _sessao({List<Address> enderecos = const []}) async {
  final auth = AuthProvider(
    service: MockUserProfileService(
      atraso: Duration.zero,
      perfilInicial: UserProfile(
        id: 'u1',
        name: 'Ana Souza',
        phone: '(16) 98888-1234',
        email: 'ana@exemplo.com',
        addresses: enderecos,
      ),
    ),
  );
  await auth.login('ana@exemplo.com', '1234');
  return auth;
}

/// Serviço de pedido determinístico, sem o delay artificial do mock real.
class _PedidoFalso implements OrderService {
  OrderRequest? ultimoPedido;

  @override
  Future<OrderResult> enviarPedido(OrderRequest pedido) async {
    ultimoPedido = pedido;
    return const OrderResult(success: true, orderNumber: '#MM000123');
  }
}

Widget _wrapComProviders(Widget child, {required AuthProvider auth, CartProvider? cartProvider}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: auth),
      ChangeNotifierProvider(create: (_) => cartProvider ?? (CartProvider()..addProduct(_produtoTeste))),
      ChangeNotifierProvider(create: (_) => ProductProvider()),
      ChangeNotifierProvider(create: (_) => OrderHistoryProvider()),
    ],
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
  testWidgets('Por padrão pede endereço; alternar para retirada troca o formulário', (tester) async {
    await tester.pumpWidget(
      _wrapComProviders(const CheckoutScreen(), auth: await _sessao()),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    expect(find.text('Rua'), findsOneWidget);
    expect(find.text('Sua compra estará pronta em 30 minutos'), findsNothing);

    await tester.tap(find.text('Retirar no Local'));
    await tester.pumpAndSettle();

    expect(find.text('Rua'), findsNothing);
    expect(find.text('Sua compra estará pronta em 30 minutos'), findsOneWidget);
  });

  testWidgets('Confirmar fica desativado até preencher o endereço (com CEP, cidade e UF) e escolher pagamento', (tester) async {
    await tester.pumpWidget(
      _wrapComProviders(const CheckoutScreen(), auth: await _sessao()),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    bool botaoConfirmarAtivo() =>
        tester.widget<ElevatedButton>(find.byType(ElevatedButton).last).onPressed != null;

    expect(botaoConfirmarAtivo(), isFalse);

    await tester.enterText(find.widgetWithText(TextFormField, 'Nome da rua'), 'Rua das Flores');
    await tester.enterText(find.widgetWithText(TextFormField, 'Nº'), '100');
    await tester.enterText(find.widgetWithText(TextFormField, 'Seu bairro'), 'Centro');
    await tester.enterText(find.widgetWithText(TextFormField, '00000-000'), '14900000');
    await tester.enterText(find.widgetWithText(TextFormField, 'Sua cidade'), 'Itápolis');
    await tester.enterText(find.widgetWithText(TextFormField, 'SP'), 'SP');
    await tester.pump();

    expect(botaoConfirmarAtivo(), isFalse); // ainda falta a forma de pagamento

    await tester.ensureVisible(find.text('Pix'));
    await tester.tap(find.text('Pix'));
    await tester.pump();

    expect(botaoConfirmarAtivo(), isTrue);
  });

  testWidgets('Endereço principal do perfil já vem preenchido', (tester) async {
    await tester.pumpWidget(
      _wrapComProviders(const CheckoutScreen(), auth: await _sessao(enderecos: const [_outro, _principal])),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextFormField, 'Rua das Palmeiras'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '120'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Jardim Itápolis'), findsOneWidget);
    // Já é um endereço salvo: não faz sentido oferecer salvar de novo.
    expect(find.text('Salvar este endereço para próximas compras'), findsNothing);
  });

  testWidgets('"Endereços salvos" permite trocar pelo outro endereço do perfil', (tester) async {
    await tester.pumpWidget(
      _wrapComProviders(const CheckoutScreen(), auth: await _sessao(enderecos: const [_principal, _outro])),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Endereços salvos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Avenida Florência, 455'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextFormField, 'Avenida Florência'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Centro'), findsOneWidget);
  });

  testWidgets('Sem endereço salvo, os campos começam vazios e sem o atalho', (tester) async {
    await tester.pumpWidget(_wrapComProviders(const CheckoutScreen(), auth: await _sessao()));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    expect(find.text('Endereços salvos'), findsNothing);
    expect(find.widgetWithText(TextFormField, 'Nome da rua'), findsOneWidget);
  });

  testWidgets('"Salvar este endereço" grava o endereço no perfil ao confirmar', (tester) async {
    final auth = await _sessao();
    await tester.pumpWidget(_wrapComProviders(CheckoutScreen(orderService: _PedidoFalso()), auth: auth));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Nome da rua'), 'Rua das Flores');
    await tester.enterText(find.widgetWithText(TextFormField, 'Nº'), '100');
    await tester.enterText(find.widgetWithText(TextFormField, 'Seu bairro'), 'Centro');
    await tester.enterText(find.widgetWithText(TextFormField, '00000-000'), '14900000');
    await tester.enterText(find.widgetWithText(TextFormField, 'Sua cidade'), 'Itápolis');
    await tester.enterText(find.widgetWithText(TextFormField, 'SP'), 'SP');
    await tester.pump();
    await tester.ensureVisible(find.text('Salvar este endereço para próximas compras'));
    await tester.tap(find.text('Salvar este endereço para próximas compras'));
    await tester.ensureVisible(find.text('Pix'));
    await tester.tap(find.text('Pix'));
    await tester.pump();

    await tester.ensureVisible(find.text('CONFIRMAR PEDIDO'));
    await tester.tap(find.text('CONFIRMAR PEDIDO'));
    await tester.pumpAndSettle();

    final salvos = auth.usuario!.addresses;
    expect(salvos, hasLength(1));
    expect(salvos.single.linhaPrincipal, 'Rua das Flores, 100');
    expect(salvos.single.isMain, isTrue); // primeiro endereço vira o principal
  });

  testWidgets('Retirada no local não soma taxa de entrega ao total', (tester) async {
    await tester.pumpWidget(
      _wrapComProviders(const CheckoutScreen(), auth: await _sessao()),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    expect(find.text('Taxa de entrega'), findsOneWidget);

    await tester.tap(find.text('Retirar no Local'));
    await tester.pumpAndSettle();

    expect(find.text('Taxa de entrega'), findsNothing);
  });

  testWidgets('Confirmar pedido envia os dados corretos e navega para a confirmação', (tester) async {
    final pedidoFalso = _PedidoFalso();

    await tester.pumpWidget(
      _wrapComProviders(CheckoutScreen(orderService: pedidoFalso), auth: await _sessao()),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Retirar no Local'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Dinheiro'));
    await tester.tap(find.text('Dinheiro'));
    await tester.pump();

    await tester.ensureVisible(find.text('CONFIRMAR PEDIDO'));
    await tester.tap(find.text('CONFIRMAR PEDIDO'));
    await tester.pumpAndSettle();

    expect(find.text('Seu pedido foi recebido!'), findsOneWidget);
    expect(find.text('#MM000123'), findsOneWidget);

    expect(pedidoFalso.ultimoPedido, isNotNull);
    expect(pedidoFalso.ultimoPedido!.deliveryAddress, isNull); // retirada não tem endereço
    expect(pedidoFalso.ultimoPedido!.total, 24.90); // sem taxa de entrega
  });

  testWidgets('Abrir o checkout também esconde SnackBars de "produto adicionado" pendentes', (tester) async {
    final cart = CartProvider()..addProduct(_produtoTeste);
    final auth = await _sessao();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: auth),
          ChangeNotifierProvider<CartProvider>.value(value: cart),
          ChangeNotifierProvider(create: (_) => ProductProvider()),
          ChangeNotifierProvider(create: (_) => OrderHistoryProvider()),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Espaguete Tradicional adicionado ao carrinho')),
                    );
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const CheckoutScreen(),
                      ),
                    );
                  },
                  child: const Text('adicionar e abrir checkout'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('adicionar e abrir checkout'));
    await tester.pumpAndSettle();

    expect(find.textContaining('adicionado ao carrinho'), findsNothing);
  });
}
