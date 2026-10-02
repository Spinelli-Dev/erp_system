// Testes do cadastro de cliente, da regra de taxa de entrega definida pelos
// gestores (com o aviso de entrega grátis) e do histórico vindo do backend
// (status atualizado, erro e logout no meio da busca).

import 'dart:async';

import 'package:app_cliente/core/validators.dart';
import 'package:app_cliente/models/cart_item.dart';
import 'package:app_cliente/models/delivery_fee_rule.dart';
import 'package:app_cliente/models/delivery_type.dart';
import 'package:app_cliente/models/order_confirmation.dart';
import 'package:app_cliente/models/order_status.dart';
import 'package:app_cliente/models/payment_method.dart';
import 'package:app_cliente/models/product.dart';
import 'package:app_cliente/models/user_profile.dart';
import 'package:app_cliente/navigation/app_router.dart';
import 'package:app_cliente/providers/auth_provider.dart';
import 'package:app_cliente/providers/cart_provider.dart';
import 'package:app_cliente/providers/navigation_provider.dart';
import 'package:app_cliente/providers/order_history_provider.dart';
import 'package:app_cliente/providers/product_provider.dart';
import 'package:app_cliente/screens/login_screen.dart';
import 'package:app_cliente/screens/order_history_screen.dart';
import 'package:app_cliente/services/delivery_fee_service.dart';
import 'package:app_cliente/services/franchise_service.dart';
import 'package:app_cliente/services/order_service.dart';
import 'package:app_cliente/services/user_profile_service.dart';
import 'package:app_cliente/widgets/free_delivery_hint.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

const _massa = Product(id: '1', name: 'Espaguete Tradicional', description: '', price: 24.90, category: 'Massas');

/// Serviço de perfil sem latência, que pode recusar o cadastro.
class _PerfilFalso extends MockUserProfileService {
  _PerfilFalso({this.erroCadastro}) : super(atraso: Duration.zero);

  final String? erroCadastro;
  String? emailCadastrado;

  @override
  Future<UserProfile> cadastrar({
    required String name,
    required String email,
    required String phone,
    required String senha,
  }) {
    if (erroCadastro != null) throw UserProfileException(erroCadastro!);
    emailCadastrado = email;
    return super.cadastrar(name: name, email: email, phone: phone, senha: senha);
  }
}

class _RegraFixa implements DeliveryFeeService {
  const _RegraFixa(this.regra);
  final DeliveryFeeRule regra;

  @override
  Future<DeliveryFeeRule> buscarRegra() async => regra;
}

/// Histórico controlado pelo teste: cada busca espera o [Completer] atual.
class _HistoricoControlado implements OrderHistoryService {
  Completer<List<OrderConfirmation>> resposta = Completer();

  @override
  Future<List<OrderConfirmation>> buscarPedidos() => resposta.future;
}

OrderConfirmation _pedido(String id, {OrderStatus status = OrderStatus.recebido, DateTime? data}) => OrderConfirmation(
      orderId: id,
      orderDate: data ?? DateTime.now(),
      deliveryType: DeliveryType.pickup,
      pickupLocation: franquiaPadrao,
      items: [CartItem(product: _massa)],
      paymentMethod: PaymentMethod.pix,
      subtotal: 24.90,
      deliveryFee: 0,
      total: 24.90,
      estimatedTimeMinutes: 30,
      paymentInstructions: '',
      status: status,
    );

Widget _app({required AuthProvider auth}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: auth),
      ChangeNotifierProvider(create: (_) => NavigationProvider()),
      ChangeNotifierProvider(create: (_) => CartProvider()),
      ChangeNotifierProvider(create: (_) => ProductProvider()),
      ChangeNotifierProvider(create: (_) => OrderHistoryProvider()),
    ],
    child: Builder(
      builder: (context) {
        final router = AppRouter(auth);
        return MaterialApp(
          initialRoute: '/produtos',
          onGenerateInitialRoutes: router.gerarRotasIniciais,
          onGenerateRoute: router.gerarRota,
        );
      },
    ),
  );
}

Future<void> _abrirCadastro(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Cadastre-se'));
  await tester.tap(find.text('Cadastre-se'));
  await tester.pumpAndSettle();
}

Future<void> _preencherCadastro(WidgetTester tester, {String confirmacao = 'segredo1'}) async {
  final campos = find.byType(TextFormField);
  await tester.enterText(campos.at(0), 'Ana Souza');
  await tester.enterText(campos.at(1), 'ana@exemplo.com');
  await tester.enterText(campos.at(2), '16988881234');
  await tester.enterText(campos.at(3), 'segredo1');
  await tester.enterText(campos.at(4), confirmacao);
}

Future<void> _tocarCriarConta(WidgetTester tester) async {
  await tester.ensureVisible(find.text('CRIAR CONTA'));
  await tester.tap(find.text('CRIAR CONTA'));
  await tester.pumpAndSettle();
}

void main() {
  group('Cadastro', () {
    testWidgets('"Cadastre-se" abre o cadastro e valida os campos', (tester) async {
      await tester.pumpWidget(_app(auth: AuthProvider(service: _PerfilFalso())));
      await _abrirCadastro(tester);

      expect(find.text('Crie sua conta'), findsOneWidget);
      await _tocarCriarConta(tester);

      expect(find.text('Informe seu nome'), findsOneWidget);
      expect(find.text('Informe seu e-mail'), findsOneWidget);
      expect(find.text('Informe seu telefone'), findsOneWidget);
      expect(find.text('Crie uma senha'), findsOneWidget);
    });

    testWidgets('senhas diferentes não deixam criar a conta', (tester) async {
      final servico = _PerfilFalso();
      await tester.pumpWidget(_app(auth: AuthProvider(service: servico)));
      await _abrirCadastro(tester);

      await _preencherCadastro(tester, confirmacao: 'outra123');
      await _tocarCriarConta(tester);

      expect(find.text('As senhas não conferem'), findsOneWidget);
      expect(servico.emailCadastrado, isNull);
    });

    testWidgets('cadastro com sucesso já entra no app, sem voltar ao login', (tester) async {
      final servico = _PerfilFalso();
      final auth = AuthProvider(service: servico);
      await tester.pumpWidget(_app(auth: auth));
      await _abrirCadastro(tester);

      await _preencherCadastro(tester);
      await _tocarCriarConta(tester);

      expect(servico.emailCadastrado, 'ana@exemplo.com');
      expect(auth.usuario?.name, 'Ana Souza');
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('Crie sua conta'), findsNothing);
      expect(find.text('Acesse sua conta'), findsNothing);
    });

    testWidgets('erro do servidor (e-mail em uso) aparece na tela', (tester) async {
      await tester.pumpWidget(
        _app(auth: AuthProvider(service: _PerfilFalso(erroCadastro: 'Este e-mail ja esta cadastrado.'))),
      );
      await _abrirCadastro(tester);

      await _preencherCadastro(tester);
      await _tocarCriarConta(tester);

      expect(find.text('Este e-mail ja esta cadastrado.'), findsOneWidget);
      expect(find.text('Crie sua conta'), findsOneWidget);
    });
  });

  group('Senha', () {
    test('regra: 8+ caracteres, ao menos uma letra e um número', () {
      expect(validarSenhaNova(''), 'Crie uma senha');
      expect(validarSenhaNova('abc1234'), isNotNull, reason: 'só 7 caracteres');
      expect(validarSenhaNova('abcdefgh'), isNotNull, reason: 'sem número');
      expect(validarSenhaNova('12345678'), isNotNull, reason: 'sem letra');
      expect(validarSenhaNova('senha123'), isNull);
      expect(validarSenhaNova('maçã2026'), isNull, reason: 'letra acentuada também conta');
    });

    /// Ícone de cada item do checklist, na ordem em que aparecem.
    List<IconData?> icones(WidgetTester tester) => [
          for (final regra in regrasSenha)
            tester
                .widget<Icon>(find.descendant(
                  of: find.ancestor(of: find.text(regra.descricao), matching: find.byType(Row)),
                  matching: find.byType(Icon),
                ))
                .icon,
        ];

    testWidgets('checklist aparece antes de digitar e marca cada requisito', (tester) async {
      await tester.pumpWidget(_app(auth: AuthProvider(service: _PerfilFalso())));
      await _abrirCadastro(tester);

      // Visível desde o início, tudo pendente.
      expect(find.text('Pelo menos 8 caracteres'), findsOneWidget);
      expect(find.text('Pelo menos uma letra'), findsOneWidget);
      expect(find.text('Pelo menos um número'), findsOneWidget);
      expect(icones(tester), everyElement(Icons.radio_button_unchecked));

      final senha = find.byType(TextFormField).at(3);
      await tester.enterText(senha, 'abc');
      await tester.pumpAndSettle();
      expect(icones(tester), [Icons.radio_button_unchecked, Icons.check_circle, Icons.radio_button_unchecked]);

      await tester.enterText(senha, 'abcdefg1');
      await tester.pumpAndSettle();
      expect(icones(tester), everyElement(Icons.check_circle));
    });

    testWidgets('senha fora da regra não deixa criar a conta', (tester) async {
      final servico = _PerfilFalso();
      await tester.pumpWidget(_app(auth: AuthProvider(service: servico)));
      await _abrirCadastro(tester);

      final campos = find.byType(TextFormField);
      await tester.enterText(campos.at(0), 'Ana Souza');
      await tester.enterText(campos.at(1), 'ana@exemplo.com');
      await tester.enterText(campos.at(2), '16988881234');
      await tester.enterText(campos.at(3), 'abcdefgh');
      await tester.enterText(campos.at(4), 'abcdefgh');
      await _tocarCriarConta(tester);

      expect(find.text('A senha ainda não atende aos requisitos'), findsOneWidget);
      expect(servico.emailCadastrado, isNull);
    });

    testWidgets('login aceita senha curta de conta antiga: só exige preenchida', (tester) async {
      String? senhaEnviada;
      await tester.pumpWidget(MaterialApp(
        home: LoginScreen(onLogin: (email, senha) async {
          senhaEnviada = senha;
          return 'E-mail ou senha incorretos.';
        }),
      ));

      await tester.ensureVisible(find.text('ENTRAR'));
      await tester.tap(find.text('ENTRAR'));
      await tester.pump();
      expect(find.text('Informe sua senha'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).at(0), 'antigo@exemplo.com');
      await tester.enterText(find.byType(TextFormField).at(1), '123');
      await tester.tap(find.text('ENTRAR'));
      await tester.pumpAndSettle();

      expect(senhaEnviada, '123', reason: 'quem decide é o servidor, não a tela');
    });
  });

  group('Taxa de entrega', () {
    test('regra: cobra a taxa fixa até o pedido mínimo, depois é grátis', () {
      const regra = DeliveryFeeRule(fee: 7.5, freeDeliveryFrom: 60);

      expect(regra.taxaPara(59.99), 7.5);
      expect(regra.taxaPara(60), 0);
      expect(regra.faltaParaGratis(45.80), closeTo(14.20, 0.001));
      expect(regra.faltaParaGratis(60), isNull);
      // Sem pedido mínimo: sempre cobra, e não há o que "faltar".
      expect(const DeliveryFeeRule(fee: 5).taxaPara(1000), 5);
      expect(const DeliveryFeeRule(fee: 5).faltaParaGratis(10), isNull);
    });

    test('carrinho usa a regra que veio do backend', () async {
      final cart = CartProvider(deliveryFeeService: const _RegraFixa(DeliveryFeeRule(fee: 7.5, freeDeliveryFrom: 60)));
      await cart.atualizarRegraEntrega();

      expect(cart.taxaEntrega, 0, reason: 'carrinho vazio não tem taxa');
      cart.addProduct(_massa); // 24,90
      expect(cart.resumo.taxaEntrega, 7.5);
      cart.addProduct(_massa, quantity: 2); // 74,70
      expect(cart.resumo.taxaEntrega, 0);
      expect(cart.resumo.total, closeTo(74.70, 0.001));
    });

    testWidgets('aviso mostra quanto falta e, depois, que a entrega é grátis', (tester) async {
      Widget aviso(double subtotal) => MaterialApp(
            home: Scaffold(
              body: FreeDeliveryHint(regra: const DeliveryFeeRule(fee: 7.5, freeDeliveryFrom: 60), subtotal: subtotal),
            ),
          );

      await tester.pumpWidget(aviso(45.80));
      expect(find.textContaining('14,20 para a entrega grátis'), findsOneWidget);

      await tester.pumpWidget(aviso(60));
      expect(find.text('Você ganhou entrega grátis!'), findsOneWidget);
    });

    testWidgets('sem pedido mínimo cadastrado, o aviso não aparece', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: FreeDeliveryHint(regra: DeliveryFeeRule(fee: 7.5), subtotal: 30)),
      ));

      expect(find.textContaining('entrega grátis'), findsNothing);
    });
  });

  group('Histórico pela API', () {
    test('carregar troca a lista pela do backend, mais recentes primeiro', () async {
      final api = _HistoricoControlado();
      final historico = OrderHistoryProvider(service: api);

      final carga = historico.carregar();
      expect(historico.carregando, isTrue);
      api.resposta.complete([_pedido('#000002'), _pedido('#000001')]);
      await carga;

      expect(historico.carregando, isFalse);
      expect(historico.pedidos.map((p) => p.orderId), ['#000002', '#000001']);
    });

    test('falha mantém a lista que já estava e guarda a mensagem', () async {
      final api = _HistoricoControlado();
      final historico = OrderHistoryProvider(service: api);
      api.resposta.complete([_pedido('#000001')]);
      await historico.carregar();

      api.resposta = Completer()..completeError(Exception('offline'));
      await historico.carregar();

      expect(historico.pedidos.map((p) => p.orderId), ['#000001']);
      expect(historico.erro, contains('Não foi possível carregar'));
    });

    test('logout no meio da busca descarta a resposta do cliente que saiu', () async {
      final api = _HistoricoControlado();
      final historico = OrderHistoryProvider(service: api);

      final carga = historico.carregar();
      historico.limpar();
      api.resposta.complete([_pedido('#000001')]);
      await carga;

      expect(historico.isEmpty, isTrue);
      expect(historico.carregando, isFalse);
    });

    testWidgets('tela mostra o status de cada pedido e o erro com "Tentar novamente"', (tester) async {
      final api = _HistoricoControlado()..resposta.completeError(Exception('offline'));
      final historico = OrderHistoryProvider(service: api);

      Future<void> abrir() => tester.pumpWidget(MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: historico),
              ChangeNotifierProvider(create: (_) => CartProvider()),
              ChangeNotifierProvider(create: (_) => ProductProvider()),
              ChangeNotifierProvider(create: (_) => NavigationProvider()),
            ],
            child: const MaterialApp(home: OrderHistoryScreen()),
          ));

      await historico.carregar();
      await abrir();
      expect(find.text('Tentar novamente'), findsOneWidget);

      api.resposta = Completer()
        ..complete([
          _pedido('#000002', status: OrderStatus.saiuParaEntrega),
          _pedido('#000001', status: OrderStatus.cancelado),
        ]);
      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle();

      expect(find.text('Saiu para entrega'), findsOneWidget);
      expect(find.text('Cancelado'), findsOneWidget);
    });
  });
}
