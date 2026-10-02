// Teste básico de widget para a tela de login do app_cliente.
//
// Verifica se a LoginScreen renderiza os elementos principais e valida
// o formulário quando o botão "ENTRAR" é pressionado sem preenchimento.

import 'package:flutter_test/flutter_test.dart';

import 'package:app_cliente/main.dart';

void main() {
  testWidgets('LoginScreen exibe título, campos e botão de entrar', (WidgetTester tester) async {
    await tester.pumpWidget(const MaxiMassasApp());

    expect(find.text('Acesse sua conta'), findsOneWidget);
    expect(find.text('E-mail'), findsOneWidget);
    expect(find.text('Senha'), findsOneWidget);
    expect(find.text('ENTRAR'), findsOneWidget);
  });

  testWidgets('Mostra mensagens de validação ao enviar formulário vazio', (WidgetTester tester) async {
    await tester.pumpWidget(const MaxiMassasApp());

    await tester.ensureVisible(find.text('ENTRAR'));
    await tester.tap(find.text('ENTRAR'));
    await tester.pump();

    expect(find.text('Informe seu e-mail'), findsOneWidget);
    expect(find.text('Informe sua senha'), findsOneWidget);
  });
}
