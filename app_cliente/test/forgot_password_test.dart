// Testes do "Esqueci minha senha" do app: pedir o código por e-mail,
// digitar o código + nova senha e voltar ao login já preenchido.

import 'package:app_cliente/providers/auth_provider.dart';
import 'package:app_cliente/screens/login_screen.dart';
import 'package:app_cliente/services/user_profile_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// Mock sem latência que registra o que a tela pediu.
class _SenhaFalsa extends MockUserProfileService {
  _SenhaFalsa() : super(atraso: Duration.zero);

  final pedidos = <String>[];
  String? senhaGravada;

  @override
  Future<void> solicitarCodigoSenha(String email) async => pedidos.add(email);

  @override
  Future<void> redefinirSenha({required String email, required String codigo, required String novaSenha}) async {
    await super.redefinirSenha(email: email, codigo: codigo, novaSenha: novaSenha);
    senhaGravada = novaSenha;
  }
}

Future<void> _abrirTela(WidgetTester tester, _SenhaFalsa servico) async {
  await tester.pumpWidget(ChangeNotifierProvider(
    create: (_) => AuthProvider(service: servico),
    child: const MaterialApp(home: LoginScreen()),
  ));
  await tester.enterText(find.byType(TextFormField).first, 'ana@exemplo.com');
  await tester.tap(find.text('Esqueci minha senha'));
  await tester.pumpAndSettle();
}

Future<void> _tocar(WidgetTester tester, String texto) async {
  await tester.ensureVisible(find.text(texto));
  await tester.tap(find.text(texto));
  await tester.pump();
}

void main() {
  testWidgets('pede o código, cria a nova senha e volta ao login preenchido', (tester) async {
    final servico = _SenhaFalsa();
    await _abrirTela(tester, servico);

    // O e-mail digitado no login já vem preenchido.
    expect(find.text('ana@exemplo.com'), findsOneWidget);
    await _tocar(tester, 'ENVIAR CÓDIGO');
    await tester.pump();

    expect(servico.pedidos, ['ana@exemplo.com']);
    expect(find.text('Criar nova senha'), findsOneWidget);
    expect(find.text('Reenviar em 60s'), findsOneWidget, reason: 'mesmo intervalo do servidor entre e-mails');

    final campos = find.byType(TextFormField);
    await tester.enterText(campos.at(0), '12-34-56'); // a máscara deixa só os dígitos
    await tester.enterText(campos.at(1), 'novaSenha9');
    await tester.enterText(campos.at(2), 'novaSenha9');
    await _tocar(tester, 'SALVAR NOVA SENHA');
    await tester.pumpAndSettle();

    expect(servico.senhaGravada, 'novaSenha9');
    expect(find.text('Senha alterada! Entre com a nova senha.'), findsOneWidget);
    expect(find.text('Acesse sua conta'), findsOneWidget);
  });

  testWidgets('código errado mostra o erro e senha fraca nem chega ao servidor', (tester) async {
    final servico = _SenhaFalsa();
    await _abrirTela(tester, servico);
    await _tocar(tester, 'ENVIAR CÓDIGO');
    await tester.pump();

    final campos = find.byType(TextFormField);
    await tester.enterText(campos.at(0), '123456');
    await tester.enterText(campos.at(1), 'abcdefgh');
    await tester.enterText(campos.at(2), 'abcdefgh');
    await _tocar(tester, 'SALVAR NOVA SENHA');
    expect(find.text('A senha ainda não atende aos requisitos'), findsOneWidget);
    expect(servico.senhaGravada, isNull);

    await tester.enterText(campos.at(0), '999999');
    await tester.enterText(campos.at(1), 'novaSenha9');
    await tester.enterText(campos.at(2), 'novaSenha9');
    await _tocar(tester, 'SALVAR NOVA SENHA');
    await tester.pumpAndSettle();

    expect(find.text('Código incorreto. Confira o e-mail e tente de novo.'), findsOneWidget);
    expect(servico.senhaGravada, isNull);

    // Depois de 60 s dá para pedir outro código.
    await tester.pump(const Duration(seconds: 61));
    await _tocar(tester, 'Reenviar código');
    await tester.pump();
    expect(servico.pedidos, hasLength(2));
  });

  testWidgets('"Trocar e-mail" volta para a primeira etapa', (tester) async {
    final servico = _SenhaFalsa();
    await _abrirTela(tester, servico);
    await _tocar(tester, 'ENVIAR CÓDIGO');
    await tester.pump();

    await _tocar(tester, 'Trocar e-mail');
    expect(find.text('ENVIAR CÓDIGO'), findsOneWidget);
  });
}
