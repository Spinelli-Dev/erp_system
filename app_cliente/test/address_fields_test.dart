// Testes dos campos de endereço com preenchimento pelo CEP (usados no
// Perfil e na finalização do pedido).

import 'package:app_cliente/models/address.dart';
import 'package:app_cliente/services/api_client.dart';
import 'package:app_cliente/services/cep_service.dart';
import 'package:app_cliente/widgets/address_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// CEP de mentira: um endereço conhecido, um CEP geral de cidade (sem rua)
/// e falha de conexão; qualquer outro "não existe".
class _CepFalso implements CepService {
  final consultados = <String>[];

  @override
  Future<CepResult?> buscar(String cep) async {
    consultados.add(cep);
    return switch (cep) {
      '14906618' => const CepResult(
          zipCode: '14906-618', street: 'Rua H', neighborhood: 'Residencial Montreal', city: 'Itápolis', state: 'SP'),
      '14900000' => const CepResult(zipCode: '14900-000', street: '', neighborhood: '', city: 'Itápolis', state: 'SP'),
      '00000001' => throw const ApiException('offline'),
      _ => null,
    };
  }
}

Future<(AddressFieldsController, _CepFalso)> _montar(WidgetTester tester, {Address? inicial}) async {
  final controller = AddressFieldsController();
  if (inicial != null) controller.preencher(inicial);
  final cep = _CepFalso();
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(child: AddressFields(controller: controller, cepService: cep)),
    ),
  ));
  addTearDown(controller.dispose);
  return (controller, cep);
}

Finder _campo(String dica) => find.widgetWithText(TextFormField, dica);

void main() {
  testWidgets('CEP completo preenche rua, bairro, cidade e UF', (tester) async {
    final (c, cep) = await _montar(tester);

    await tester.enterText(_campo('00000-000'), '14906618');
    await tester.pumpAndSettle();

    expect(cep.consultados, ['14906618']);
    expect(c.rua.text, 'Rua H');
    expect(c.bairro.text, 'Residencial Montreal');
    expect(c.cidade.text, 'Itápolis');
    expect(c.estado.text, 'SP');
    expect(c.numero.text, isEmpty, reason: 'número é sempre do cliente');
  });

  testWidgets('CEP geral da cidade não apaga rua e bairro já digitados', (tester) async {
    final (c, _) = await _montar(tester);
    await tester.enterText(_campo('Nome da rua'), 'Rua das Palmeiras');
    await tester.enterText(_campo('Seu bairro'), 'Centro');

    await tester.enterText(_campo('00000-000'), '14900000');
    await tester.pumpAndSettle();

    expect(c.rua.text, 'Rua das Palmeiras');
    expect(c.bairro.text, 'Centro');
    expect(c.cidade.text, 'Itápolis');
  });

  testWidgets('CEP inexistente ou sem conexão avisa e deixa preencher à mão', (tester) async {
    await _montar(tester);

    await tester.enterText(_campo('00000-000'), '99999999');
    await tester.pumpAndSettle();
    expect(find.textContaining('CEP não encontrado'), findsOneWidget);

    await tester.enterText(_campo('00000-000'), '00000001');
    await tester.pumpAndSettle();
    expect(find.textContaining('Não foi possível consultar o CEP'), findsOneWidget);
  });

  testWidgets('endereço já preenchido (salvo ou em edição) não é consultado nem sobrescrito', (tester) async {
    final (c, cep) = await _montar(
      tester,
      inicial: const Address(
        street: 'Rua do Cliente',
        number: '10',
        neighborhood: 'Bairro do Cliente',
        zipCode: '14906-618',
        city: 'Itápolis',
        state: 'SP',
      ),
    );
    await tester.pumpAndSettle();

    // Mexer no CEP e voltar ao mesmo também não dispara a consulta.
    await tester.enterText(_campo('00000-000'), '1490661');
    await tester.enterText(_campo('00000-000'), '14906618');
    await tester.pumpAndSettle();

    expect(cep.consultados, isEmpty);
    expect(c.rua.text, 'Rua do Cliente');
  });

  testWidgets('completo só com CEP válido, cidade e UF existentes', (tester) async {
    final (c, _) = await _montar(tester);
    c.preencher(const Address(street: 'Rua A', number: '1', neighborhood: 'Centro', zipCode: '14906-618', city: 'Itápolis'));
    expect(c.completo, isFalse, reason: 'sem UF');

    c.estado.text = 'XX';
    expect(c.completo, isFalse, reason: 'UF que não existe');

    c.estado.text = 'sp';
    expect(c.completo, isTrue);
    expect(c.montar().state, 'SP');
    expect(c.montar().cidadeUf, 'Itápolis/SP');
  });
}
