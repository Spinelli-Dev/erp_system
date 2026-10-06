// Testes da aba Perfil: edição dos dados pessoais (com validação e
// máscara) e o CRUD de endereços salvos, incluindo a regra de um único
// endereço principal.

import 'package:app_cliente/core/validators.dart';
import 'package:app_cliente/models/address.dart';
import 'package:app_cliente/models/product.dart';
import 'package:app_cliente/models/user_profile.dart';
import 'package:app_cliente/providers/auth_provider.dart';
import 'package:app_cliente/providers/cart_provider.dart';
import 'package:app_cliente/providers/navigation_provider.dart';
import 'package:app_cliente/providers/order_history_provider.dart';
import 'package:app_cliente/screens/profile_screen.dart';
import 'package:app_cliente/services/user_profile_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

const _casa = Address(
  id: 'e1',
  street: 'Rua das Palmeiras',
  number: '120',
  complement: 'Apto 21',
  neighborhood: 'Jardim Itápolis',
  zipCode: '15900-000',
  city: 'Itápolis',
  state: 'SP',
  isMain: true,
);

const _trabalho = Address(
  id: 'e2',
  street: 'Avenida Florência',
  number: '455',
  neighborhood: 'Centro',
  zipCode: '15900-020',
  city: 'Itápolis',
  state: 'SP',
);

/// Serviço que falha em toda escrita, para testar a mensagem de erro.
class _ServicoComErro extends MockUserProfileService {
  _ServicoComErro({super.perfilInicial}) : super(atraso: Duration.zero);

  @override
  Future<UserProfile> atualizarDados({required String name, required String email, required String phone}) async =>
      throw const UserProfileException('Este e-mail já está em uso.');
}

/// O formulário de endereço é uma lista: rola até o [texto] antes de tocar.
Future<void> _tocarRolando(WidgetTester tester, String texto) async {
  final lista = find.ancestor(of: find.text('CEP'), matching: find.byType(Scrollable)).first;
  await tester.scrollUntilVisible(find.text(texto), 150, scrollable: lista);
  await tester.tap(find.text(texto));
}

Future<AuthProvider> _sessao({List<Address> enderecos = const [_casa, _trabalho], UserProfileService? servico}) async {
  final auth = AuthProvider(
    service: servico ??
        MockUserProfileService(
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

Widget _wrap(AuthProvider auth, {CartProvider? cart}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: auth),
      ChangeNotifierProvider.value(value: cart ?? CartProvider()),
      ChangeNotifierProvider(create: (_) => OrderHistoryProvider()),
      ChangeNotifierProvider(create: (_) => NavigationProvider()),
    ],
    child: const MaterialApp(home: ProfileScreen()),
  );
}

void main() {
  group('Máscaras e validações', () {
    test('Telefone e CEP recebem a máscara e só aceitam o número certo de dígitos', () {
      expect(MascaraNumerica.telefone.aplicar('16988881234'), '(16) 98888-1234');
      expect(MascaraNumerica.telefone.aplicar('169888812345678'), '(16) 98888-1234');
      expect(MascaraNumerica.telefone.aplicar('169'), '(16) 9');
      expect(MascaraNumerica.cep.aplicar('15900000'), '15900-000');

      expect(validarTelefone('(16) 98888-1234'), isNull);
      expect(validarTelefone('(16) 8888-1234'), isNotNull);
      expect(validarCep('15900-000'), isNull);
      expect(validarCep(''), isNotNull);
      expect(validarCep('', obrigatorio: false), isNull);
      expect(validarEmail('ana@exemplo'), isNotNull);
    });
  });

  group('Editar dados', () {
    testWidgets('Campos vêm preenchidos; salvar atualiza o Perfil e mostra a confirmação', (tester) async {
      final auth = await _sessao();
      await tester.pumpWidget(_wrap(auth));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Editar dados'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextFormField, 'Ana Souza'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'ana@exemplo.com'), findsOneWidget);

      await tester.enterText(find.widgetWithText(TextFormField, 'Ana Souza'), 'Ana Paula Souza');
      await tester.enterText(find.widgetWithText(TextFormField, '(16) 98888-1234'), '16977776666');
      await tester.tap(find.text('SALVAR ALTERAÇÕES'));
      await tester.pumpAndSettle();

      expect(find.text('Editar Dados'), findsNothing); // voltou ao Perfil
      expect(find.text('Dados atualizados com sucesso'), findsOneWidget);
      expect(find.text('Ana Paula Souza'), findsOneWidget);
      expect(auth.usuario!.phone, '(16) 97777-6666');
    });

    testWidgets('Valida nome, e-mail e telefone antes de enviar', (tester) async {
      final auth = await _sessao();
      await tester.pumpWidget(_wrap(auth));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Editar dados'));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextFormField, 'Ana Souza'), '');
      await tester.enterText(find.widgetWithText(TextFormField, 'ana@exemplo.com'), 'ana@');
      await tester.enterText(find.widgetWithText(TextFormField, '(16) 98888-1234'), '1698');
      await tester.tap(find.text('SALVAR ALTERAÇÕES'));
      await tester.pumpAndSettle();

      expect(find.text('Informe seu nome'), findsOneWidget);
      expect(find.text('Informe um e-mail válido'), findsOneWidget);
      expect(find.text('Use o formato (XX) XXXXX-XXXX'), findsOneWidget);
      expect(auth.usuario!.name, 'Ana Souza');
    });

    testWidgets('Erro do backend aparece na tela e nada muda', (tester) async {
      final auth = await _sessao(
        servico: _ServicoComErro(
          perfilInicial: const UserProfile(id: 'u1', name: 'Ana Souza', phone: '(16) 98888-1234', email: 'a@a.com'),
        ),
      );
      await tester.pumpWidget(_wrap(auth));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Editar dados'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('SALVAR ALTERAÇÕES'));
      await tester.pumpAndSettle();

      expect(find.text('Este e-mail já está em uso.'), findsOneWidget);
      expect(find.text('Editar Dados'), findsOneWidget); // continua na edição
    });

    testWidgets('Cancelar volta sem alterar', (tester) async {
      final auth = await _sessao();
      await tester.pumpWidget(_wrap(auth));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Editar dados'));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextFormField, 'Ana Souza'), 'Outro Nome');
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(find.text('Meu Perfil'), findsOneWidget);
      expect(auth.usuario!.name, 'Ana Souza');
    });
  });

  group('Endereços salvos', () {
    testWidgets('Lista os endereços com o principal marcado', (tester) async {
      await tester.pumpWidget(_wrap(await _sessao()));
      await tester.pumpAndSettle();

      expect(find.text('Rua das Palmeiras, 120 - Apto 21'), findsOneWidget);
      expect(find.text('Avenida Florência, 455'), findsOneWidget);
      expect(find.text('PRINCIPAL'), findsOneWidget);
      expect(find.byIcon(Icons.star_rounded), findsOneWidget);
    });

    testWidgets('Sem endereços mostra "Nenhum endereço salvo"', (tester) async {
      await tester.pumpWidget(_wrap(await _sessao(enderecos: const [])));
      await tester.pumpAndSettle();

      expect(find.text('Nenhum endereço salvo'), findsOneWidget);
    });

    testWidgets('Novo endereço marcado como principal passa a ser o único principal', (tester) async {
      final auth = await _sessao();
      await tester.pumpWidget(_wrap(auth));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Novo Endereço'));
      await tester.pumpAndSettle();

      // Validação: CEP e demais obrigatórios.
      await _tocarRolando(tester, 'SALVAR ENDEREÇO');
      await tester.pumpAndSettle();
      expect(find.text('Informe a rua'), findsOneWidget);
      expect(find.text('Informe o CEP'), findsOneWidget);
      expect(find.text('Informe a cidade'), findsOneWidget);
      expect(find.text('Informe a UF'), findsOneWidget);

      await tester.enterText(find.widgetWithText(TextFormField, 'Nome da rua'), 'Rua Sete');
      await tester.enterText(find.widgetWithText(TextFormField, 'Nº'), '7');
      await tester.enterText(find.widgetWithText(TextFormField, 'Seu bairro'), 'Vila Nova');
      await tester.enterText(find.widgetWithText(TextFormField, '00000-000'), '15900111');
      await tester.enterText(find.widgetWithText(TextFormField, 'Sua cidade'), 'Itápolis');
      await tester.enterText(find.widgetWithText(TextFormField, 'SP'), 'sp');
      await _tocarRolando(tester, 'Marcar como principal');
      await tester.pump();
      await _tocarRolando(tester, 'SALVAR ENDEREÇO');
      await tester.pumpAndSettle();

      expect(find.text('Endereço salvo com sucesso'), findsOneWidget);
      expect(find.text('Rua Sete, 7'), findsOneWidget);
      final principais = auth.usuario!.addresses.where((e) => e.isMain).toList();
      expect(principais, hasLength(1));
      expect(principais.single.street, 'Rua Sete');
      expect(principais.single.zipCode, '15900-111');
      expect(principais.single.city, 'Itápolis');
      expect(principais.single.state, 'SP', reason: 'a UF é digitada em maiúsculas');
    });

    testWidgets('Editar abre com os campos preenchidos e salva a alteração', (tester) async {
      final auth = await _sessao();
      await tester.pumpWidget(_wrap(auth));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Editar endereço').last);
      await tester.pumpAndSettle();

      expect(find.text('Editar Endereço'), findsOneWidget);
      await tester.enterText(find.widgetWithText(TextFormField, '455'), '500');
      await _tocarRolando(tester, 'SALVAR ENDEREÇO');
      await tester.pumpAndSettle();

      expect(find.text('Endereço atualizado com sucesso'), findsOneWidget);
      expect(find.text('Avenida Florência, 500'), findsOneWidget);
      expect(auth.usuario!.addresses, hasLength(2));
    });

    testWidgets('Estrela pede confirmação e troca o principal', (tester) async {
      final auth = await _sessao();
      await tester.pumpWidget(_wrap(auth));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Definir como principal'));
      await tester.pumpAndSettle();
      expect(find.text('Definir como endereço principal?'), findsOneWidget);

      await tester.tap(find.text('Definir'));
      await tester.pumpAndSettle();

      expect(auth.usuario!.mainAddressId, 'e2');
      expect(auth.usuario!.addresses.where((e) => e.isMain), hasLength(1));
      expect(find.text('Endereço principal atualizado'), findsOneWidget);
    });

    testWidgets('Deletar o principal avisa e promove o próximo', (tester) async {
      final auth = await _sessao();
      await tester.pumpWidget(_wrap(auth));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Deletar endereço').first);
      await tester.pumpAndSettle();

      expect(find.text('Tem certeza que deseja deletar este endereço?'), findsOneWidget);
      expect(find.textContaining('Este é seu endereço principal.'), findsOneWidget);

      await tester.tap(find.text('Deletar'));
      await tester.pumpAndSettle();

      expect(find.text('Endereço removido'), findsOneWidget);
      expect(find.text('Rua das Palmeiras, 120 - Apto 21'), findsNothing);
      expect(auth.usuario!.addresses.single.id, 'e2');
      expect(auth.usuario!.mainAddressId, 'e2');
    });

    testWidgets('Cancelar a remoção mantém o endereço', (tester) async {
      final auth = await _sessao();
      await tester.pumpWidget(_wrap(auth));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Deletar endereço').last);
      await tester.pumpAndSettle();
      expect(find.textContaining('Este é seu endereço principal.'), findsNothing);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(auth.usuario!.addresses, hasLength(2));
    });
  });

  group('Sair da conta', () {
    Future<void> abrirConfirmacao(WidgetTester tester, CartProvider cart) async {
      await tester.pumpWidget(_wrap(await _sessao(), cart: cart));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('SAIR DA CONTA'), 200, scrollable: find.byType(Scrollable).first);
      await tester.tap(find.text('SAIR DA CONTA'));
      await tester.pumpAndSettle();
      expect(find.text('Sair da conta?'), findsOneWidget);
    }

    testWidgets('Com carrinho vazio não fala em descartar itens', (tester) async {
      await abrirConfirmacao(tester, CartProvider());
      expect(find.textContaining('serão descartados'), findsNothing);
    });

    testWidgets('Com itens no carrinho avisa que serão descartados', (tester) async {
      const produto = Product(id: '1', name: 'Espaguete Tradicional', description: '', price: 24.90, category: 'Massas');
      await abrirConfirmacao(tester, CartProvider()..addProduct(produto));
      expect(find.text('Os itens do seu carrinho serão descartados.'), findsOneWidget);
    });
  });
}
