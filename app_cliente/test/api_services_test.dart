// Testes dos serviços que falam com a API (/api/app), usando o MockClient
// do pacote http — sem rede. Conferem o formato do que é enviado (o
// contrato com o backend) e a tradução das respostas e erros.

import 'dart:convert';

import 'package:app_cliente/models/address.dart';
import 'package:app_cliente/models/cart_item.dart';
import 'package:app_cliente/models/delivery_type.dart';
import 'package:app_cliente/models/order_request.dart';
import 'package:app_cliente/models/order_status.dart';
import 'package:app_cliente/models/payment_method.dart';
import 'package:app_cliente/models/product.dart';
import 'package:app_cliente/services/api_client.dart';
import 'package:app_cliente/services/delivery_fee_service.dart';
import 'package:app_cliente/services/order_service.dart';
import 'package:app_cliente/services/product_service.dart';
import 'package:app_cliente/services/user_profile_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _base = 'https://api.teste/api';

http.Response _json(Object corpo, int status) =>
    http.Response.bytes(utf8.encode(jsonEncode(corpo)), status, headers: {'content-type': 'application/json'});

http.Response _ok(Object? data, {int status = 200}) =>
    _json({'success': true, 'message': '', 'data': data, 'errors': []}, status);

const _produto = Product(id: '7', name: 'Canelone', description: '', price: 39.90, category: 'Massas');

OrderRequest _pedido({DeliveryType tipo = DeliveryType.delivery, PaymentMethod pagamento = PaymentMethod.pix}) =>
    OrderRequest(
      userId: '1',
      items: [CartItem(product: _produto, quantity: 2)],
      total: 86.70,
      deliveryType: tipo,
      deliveryAddress: tipo == DeliveryType.delivery
          ? const Address(
              street: 'Rua das Palmeiras',
              number: '120',
              complement: 'Apto 21',
              neighborhood: 'Jardim Itápolis',
              zipCode: '15900-000',
              city: 'Itápolis',
              state: 'SP',
            )
          : null,
      paymentMethod: pagamento,
      specialObservations: 'Sem cebola',
      scheduledTime: tipo == DeliveryType.pickup ? '19:30' : null,
      orderDate: DateTime(2026, 10, 1, 19),
    );

void main() {
  group('ApiOrderService', () {
    test('envia o pedido no formato da API, com Basic Auth, e devolve o número', () async {
      late http.Request enviada;
      final api = ApiClient(
        baseUrl: _base,
        httpClient: MockClient((req) async {
          enviada = req;
          return _ok({'id': 1003, 'numero': '#001003'}, status: 201);
        }),
      )..definirCredenciais('ana@exemplo.com', 'segredo1');

      final resultado = await ApiOrderService(api).enviarPedido(_pedido());

      expect(resultado.success, isTrue);
      expect(resultado.orderNumber, '#001003');
      expect(enviada.method, 'POST');
      expect(enviada.url.toString(), '$_base/app/pedidos');
      expect(enviada.headers['Authorization'], 'Basic ${base64Encode(utf8.encode('ana@exemplo.com:segredo1'))}');
      expect(jsonDecode(enviada.body), {
        'itens': [
          {'produtoId': 7, 'quantidade': 2},
        ],
        'tipoEntrega': 'Entrega',
        'endereco': {
          'logradouro': 'Rua das Palmeiras',
          'numero': '120',
          'complemento': 'Apto 21',
          'bairro': 'Jardim Itápolis',
          'cep': '15900-000',
          'cidade': 'Itápolis',
          'estado': 'SP',
        },
        'horario': null,
        'formaPagamento': 'Pix',
        'observacao': 'Sem cebola',
      });
    });

    test('retirada vai sem endereço e com o horário escolhido', () async {
      late Map<String, dynamic> corpo;
      final api = ApiClient(
        baseUrl: _base,
        httpClient: MockClient((req) async {
          corpo = jsonDecode(req.body) as Map<String, dynamic>;
          return _ok({'numero': '#000001'}, status: 201);
        }),
      );

      await ApiOrderService(api).enviarPedido(_pedido(tipo: DeliveryType.pickup, pagamento: PaymentMethod.cash));

      expect(corpo['tipoEntrega'], 'Retirada');
      expect(corpo.containsKey('endereco'), isFalse);
      expect(corpo['horario'], '19:30');
      expect(corpo['formaPagamento'], 'Dinheiro');
    });

    test('mostra a mensagem de negócio da API (ex.: estoque insuficiente)', () async {
      final api = ApiClient(
        baseUrl: _base,
        httpClient: MockClient((_) async => _json({
              'success': false,
              'message': 'Estoque insuficiente para o produto ID 7.',
              'data': null,
              'errors': ['InvalidOperationException'],
            }, 400)),
      );

      final resultado = await ApiOrderService(api).enviarPedido(_pedido());

      expect(resultado.success, isFalse);
      expect(resultado.errorMessage, 'Estoque insuficiente para o produto ID 7.');
    });

    test('mostra o erro de validação do ASP.NET', () async {
      final api = ApiClient(
        baseUrl: _base,
        httpClient: MockClient((_) async => _json({
              'title': 'One or more validation errors occurred.',
              'status': 400,
              'errors': {
                'Endereco': ['Informe o endereco de entrega.'],
              },
            }, 400)),
      );

      final resultado = await ApiOrderService(api).enviarPedido(_pedido());

      expect(resultado.errorMessage, 'Informe o endereco de entrega.');
    });

    test('401 vira "sessão expirada" e falha de rede vira mensagem de conexão', () async {
      final expirada = await ApiOrderService(
        ApiClient(baseUrl: _base, httpClient: MockClient((_) async => http.Response('', 401))),
      ).enviarPedido(_pedido());
      expect(expirada.errorMessage, 'Sua sessão expirou. Entre novamente.');

      final semRede = await ApiOrderService(
        ApiClient(baseUrl: _base, httpClient: MockClient((_) async => throw http.ClientException('offline'))),
      ).enviarPedido(_pedido());
      expect(semRede.success, isFalse);
      expect(semRede.errorMessage, contains('Não foi possível conectar'));
    });
  });

  test('ApiProductService converte o cardápio da API', () async {
    final api = ApiClient(
      baseUrl: _base,
      httpClient: MockClient((req) async {
        expect(req.url.toString(), '$_base/app/produtos');
        return _ok([
          {'id': 1, 'nome': 'Canelone 4 Queijos', 'descricao': '700 g', 'preco': 39.9, 'categoria': 'Massas', 'disponivel': true},
          {'id': 2, 'nome': 'Molho Branco', 'descricao': '240 g', 'preco': 5.9, 'categoria': 'Molhos', 'disponivel': false},
        ]);
      }),
    );

    final produtos = await ApiProductService(api).fetchProducts();

    expect(produtos.map((p) => p.id), ['1', '2']);
    expect(produtos.first.name, 'Canelone 4 Queijos');
    expect(produtos.first.price, 39.9);
    expect(produtos.last.category, 'Molhos');
    expect(produtos.last.isAvailable, isFalse);
  });

  group('ApiUserProfileService', () {
    Map<String, dynamic> perfilJson({String email = 'ana@exemplo.com', List<Map<String, dynamic>> enderecos = const []}) =>
        {'id': 1002, 'nome': 'Ana Souza', 'email': email, 'telefone': '(16) 98888-1234', 'enderecos': enderecos};

    test('login válido devolve o perfil com os endereços salvos', () async {
      final api = ApiClient(
        baseUrl: _base,
        httpClient: MockClient((req) async {
          expect(req.url.toString(), '$_base/app/me');
          return _ok(perfilJson(enderecos: [
            {'id': 5, 'logradouro': 'Rua A', 'numero': '1', 'complemento': null, 'bairro': 'Centro', 'cep': '15900-000', 'cidade': 'Itápolis', 'estado': 'SP', 'principal': true},
          ]));
        }),
      );

      final perfil = await ApiUserProfileService(api).entrar('ana@exemplo.com', 'segredo1');

      expect(perfil?.id, '1002');
      expect(perfil?.mainAddress?.id, '5');
      expect(perfil?.mainAddress?.street, 'Rua A');
      expect(perfil?.mainAddress?.complement, '');
      expect(perfil?.mainAddress?.cidadeUf, 'Itápolis/SP');
    });

    test('cadastro envia os dados e as próximas chamadas já vão autenticadas', () async {
      final requisicoes = <http.Request>[];
      final api = ApiClient(
        baseUrl: _base,
        httpClient: MockClient((req) async {
          requisicoes.add(req);
          return _ok(perfilJson(), status: req.method == 'POST' ? 201 : 200);
        }),
      );
      final servico = ApiUserProfileService(api);

      final perfil =
          await servico.cadastrar(name: 'Ana Souza', email: ' ana@exemplo.com ', phone: '(16) 98888-1234', senha: 'segredo1');
      await servico.obterPerfil();

      expect(perfil.name, 'Ana Souza');
      expect(requisicoes.first.url.toString(), '$_base/app/cadastro');
      expect(requisicoes.first.headers.containsKey('Authorization'), isFalse);
      expect(jsonDecode(requisicoes.first.body),
          {'nome': 'Ana Souza', 'email': 'ana@exemplo.com', 'telefone': '(16) 98888-1234', 'senha': 'segredo1'});
      expect(requisicoes.last.headers['Authorization'], 'Basic ${base64Encode(utf8.encode('ana@exemplo.com:segredo1'))}');
    });

    test('e-mail já cadastrado vira UserProfileException com a mensagem do servidor', () async {
      final api = ApiClient(
        baseUrl: _base,
        httpClient: MockClient((_) async =>
            _json({'success': false, 'message': 'Este e-mail ja esta cadastrado.', 'data': null, 'errors': []}, 400)),
      );

      expect(
        ApiUserProfileService(api).cadastrar(name: 'A', email: 'a@a.com', phone: '1', senha: 'segredo1'),
        throwsA(isA<UserProfileException>().having((e) => e.message, 'message', 'Este e-mail ja esta cadastrado.')),
      );
    });

    test('trocar o e-mail passa a autenticar com o novo; sair esquece as credenciais', () async {
      final autorizacoes = <String?>[];
      final api = ApiClient(
        baseUrl: _base,
        httpClient: MockClient((req) async {
          autorizacoes.add(req.headers['Authorization']);
          return _ok(perfilJson(email: req.method == 'PUT' ? 'novo@exemplo.com' : 'ana@exemplo.com'));
        }),
      );
      final servico = ApiUserProfileService(api);
      await servico.entrar('ana@exemplo.com', 'segredo1');

      await servico.atualizarDados(name: 'Ana', email: 'novo@exemplo.com', phone: '(16) 98888-1234');
      await servico.obterPerfil();
      expect(autorizacoes.last, 'Basic ${base64Encode(utf8.encode('novo@exemplo.com:segredo1'))}');

      servico.sair();
      await api.get('/app/produtos');
      expect(autorizacoes.last, isNull);
    });

    test('endereços usam POST (novo), PUT (existente), DELETE e PUT .../principal', () async {
      final chamadas = <String>[];
      late Map<String, dynamic> corpoNovo;
      final api = ApiClient(
        baseUrl: _base,
        httpClient: MockClient((req) async {
          chamadas.add('${req.method} ${req.url.path}');
          if (req.method == 'POST') corpoNovo = jsonDecode(req.body) as Map<String, dynamic>;
          return _ok(perfilJson());
        }),
      );
      final servico = ApiUserProfileService(api);

      await servico.salvarEndereco(
        const Address(street: 'Rua A', number: '1', neighborhood: 'Centro', zipCode: '15900-000', city: 'Itápolis', state: 'SP', isMain: true),
      );
      await servico.salvarEndereco(const Address(id: '5', street: 'Rua B', number: '2', neighborhood: 'Centro'));
      await servico.removerEndereco('5');
      await servico.definirEnderecoPrincipal('7');

      expect(chamadas, [
        'POST /api/app/enderecos',
        'PUT /api/app/enderecos/5',
        'DELETE /api/app/enderecos/5',
        'PUT /api/app/enderecos/7/principal',
      ]);
      expect(corpoNovo, {
        'logradouro': 'Rua A',
        'numero': '1',
        'complemento': '',
        'bairro': 'Centro',
        'cep': '15900-000',
        'cidade': 'Itápolis',
        'estado': 'SP',
        'principal': true,
      });
    });

    test('endereço que não existe mais mostra a mensagem do servidor', () async {
      final api = ApiClient(
        baseUrl: _base,
        httpClient: MockClient((_) async => _json(
            {'success': false, 'message': 'Este endereco nao existe mais. Atualize a pagina.', 'data': null, 'errors': []},
            404)),
      );

      expect(
        ApiUserProfileService(api).definirEnderecoPrincipal('99'),
        throwsA(isA<UserProfileException>().having((e) => e.message, 'message', contains('nao existe mais'))),
      );
    });

    test('senha errada devolve null (a tela mostra "e-mail ou senha incorretos")', () async {
      final api = ApiClient(baseUrl: _base, httpClient: MockClient((_) async => http.Response('', 401)));

      expect(await ApiUserProfileService(api).entrar('ana@exemplo.com', 'errada'), isNull);
    });

    test('servidor fora do ar propaga o erro (a tela mostra "verifique sua conexão")', () async {
      final api = ApiClient(
        baseUrl: _base,
        httpClient: MockClient((_) async => throw http.ClientException('offline')),
      );

      expect(ApiUserProfileService(api).entrar('ana@exemplo.com', 'x'), throwsA(isA<ApiException>()));
    });

    test('esqueci minha senha: pede o código e redefine sem autenticação', () async {
      final requisicoes = <http.Request>[];
      final api = ApiClient(
        baseUrl: _base,
        httpClient: MockClient((req) async {
          requisicoes.add(req);
          return _ok(null);
        }),
      );
      final servico = ApiUserProfileService(api);

      await servico.solicitarCodigoSenha(' ana@exemplo.com ');
      await servico.redefinirSenha(email: 'ana@exemplo.com', codigo: '042137', novaSenha: 'novaSenha9');

      expect(requisicoes.map((r) => r.url.toString()), ['$_base/app/senha/esqueci', '$_base/app/senha/redefinir']);
      expect(requisicoes.every((r) => !r.headers.containsKey('Authorization')), isTrue);
      expect(jsonDecode(requisicoes.first.body), {'email': 'ana@exemplo.com'});
      expect(jsonDecode(requisicoes.last.body), {'email': 'ana@exemplo.com', 'codigo': '042137', 'novaSenha': 'novaSenha9'});
    });

    test('código errado vira UserProfileException com a mensagem do servidor', () async {
      final api = ApiClient(
        baseUrl: _base,
        httpClient: MockClient((_) async => _json(
            {'success': false, 'message': 'Código incorreto. Você ainda tem 4 tentativa(s).', 'data': null, 'errors': []}, 400)),
      );

      expect(
        ApiUserProfileService(api).redefinirSenha(email: 'a@a.com', codigo: '000000', novaSenha: 'segredo12'),
        throwsA(isA<UserProfileException>()
            .having((e) => e.message, 'message', 'Código incorreto. Você ainda tem 4 tentativa(s).')),
      );
    });
  });

  test('ApiOrderService.buscarPedidos converte o histórico da API', () async {
    final api = ApiClient(
      baseUrl: _base,
      httpClient: MockClient((req) async {
        expect(req.url.toString(), '$_base/app/pedidos');
        return _ok([
          {
            'id': 1003,
            'numero': '#001003',
            'data': '2026-10-01T23:17:54.4481899',
            'status': 'EmEntrega',
            'subtotal': 45.8,
            'taxaEntrega': 7.5,
            'total': 53.3,
            'tipoEntrega': 'Entrega',
            'endereco': {
              'id': null,
              'logradouro': 'Rua das Palmeiras',
              'numero': '120',
              'complemento': null,
              'bairro': 'Centro',
              'cep': '15900-000',
              'cidade': 'Itápolis',
              'estado': 'SP',
              'principal': false,
            },
            'horario': '',
            'formaPagamento': 'Pix',
            'statusPagamento': 'Pendente',
            'observacao': 'Sem cebola',
            'itens': [
              {'produtoId': 1, 'nome': 'Canelone 4 Queijos', 'quantidade': 1, 'precoUnitario': 39.9, 'subtotal': 39.9},
              {'produtoId': 2, 'nome': 'Molho Branco', 'quantidade': 1, 'precoUnitario': 5.9, 'subtotal': 5.9},
            ],
          },
          {
            'id': 1002,
            'numero': '#001002',
            'data': '2026-09-30T19:00:00',
            'status': 'Cancelada',
            'subtotal': 5.5,
            'taxaEntrega': 0,
            'total': 5.5,
            'tipoEntrega': 'Retirada',
            'endereco': null,
            'horario': '19:30',
            'formaPagamento': 'CartaoCredito',
            'statusPagamento': 'Cancelado',
            'observacao': null,
            'itens': [
              {'produtoId': 3, 'nome': 'Queijo Ralado', 'quantidade': 1, 'precoUnitario': 5.5, 'subtotal': 5.5},
            ],
          },
        ]);
      }),
    );

    final pedidos = await ApiOrderService(api).buscarPedidos();

    final entrega = pedidos.first;
    expect(entrega.orderId, '#001003');
    expect(entrega.orderDate.day, 1);
    expect(entrega.orderDate.hour, 23);
    expect(entrega.status, OrderStatus.saiuParaEntrega);
    expect(entrega.deliveryType, DeliveryType.delivery);
    expect(entrega.deliveryAddress?.street, 'Rua das Palmeiras');
    expect(entrega.deliveryAddress?.city, 'Itápolis');
    expect(entrega.deliveryFee, 7.5);
    expect(entrega.total, 53.3);
    expect(entrega.paymentMethod, PaymentMethod.pix);
    expect(entrega.specialObservations, 'Sem cebola');
    expect(entrega.items.map((i) => '${i.quantity}x ${i.product.name} (${i.product.id})'),
        ['1x Canelone 4 Queijos (1)', '1x Molho Branco (2)']);

    final retirada = pedidos.last;
    expect(retirada.status, OrderStatus.cancelado);
    expect(retirada.deliveryType, DeliveryType.pickup);
    expect(retirada.deliveryAddress, isNull);
    expect(retirada.paymentMethod, PaymentMethod.card);
  });

  test('ApiOrderService devolve os valores que o servidor cobrou', () async {
    final api = ApiClient(
      baseUrl: _base,
      httpClient: MockClient(
          (_) async => _ok({'numero': '#001009', 'subtotal': 79.8, 'taxaEntrega': 0, 'total': 79.8}, status: 201)),
    );

    final resultado = await ApiOrderService(api).enviarPedido(_pedido());

    expect(resultado.subtotal, 79.8);
    expect(resultado.deliveryFee, 0);
    expect(resultado.total, 79.8);
  });

  test('ApiDeliveryFeeService lê a regra definida pelos gestores', () async {
    final api = ApiClient(
      baseUrl: _base,
      httpClient: MockClient((req) async {
        expect(req.url.toString(), '$_base/app/entrega');
        return _ok({'taxaEntrega': 7.5, 'pedidoMinimoEntregaGratis': 60, 'atualizadoEm': '2026-10-01T23:40:35'});
      }),
    );

    final regra = await ApiDeliveryFeeService(api).buscarRegra();

    expect(regra.fee, 7.5);
    expect(regra.freeDeliveryFrom, 60);
  });
}
