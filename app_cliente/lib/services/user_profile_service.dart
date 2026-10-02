import '../models/address.dart';
import '../models/user_profile.dart';
import 'api_client.dart';

/// Erro de negócio vindo do backend (ex.: e-mail já em uso), com a
/// mensagem pronta para mostrar ao usuário.
class UserProfileException implements Exception {
  const UserProfileException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Acesso aos dados do cliente logado: [ApiUserProfileService] usa a API
/// (login, cadastro, perfil e endereços salvos); [MockUserProfileService]
/// simula tudo quando o app roda sem API configurada (ver `main.dart`).
///
/// Toda operação de escrita devolve o perfil completo já atualizado: o
/// backend é quem decide o resultado final (ex.: qual endereço vira o
/// principal depois de apagar o atual), e o app só espelha a resposta.
abstract class UserProfileService {
  /// Autentica e devolve o perfil, ou `null` se as credenciais não conferem.
  Future<UserProfile?> entrar(String email, String senha);

  /// Cria a conta e já entra com ela. Lança [UserProfileException] com a
  /// mensagem do backend (ex.: e-mail já cadastrado).
  Future<UserProfile> cadastrar({
    required String name,
    required String email,
    required String phone,
    required String senha,
  });

  /// Encerra a sessão no serviço (esquece as credenciais guardadas).
  void sair();

  Future<UserProfile?> obterPerfil();

  Future<UserProfile> atualizarDados({required String name, required String email, required String phone});

  /// [endereco] sem `id` cria um novo; com `id`, atualiza o existente.
  /// `isMain: true` o torna o principal (e desmarca o anterior).
  Future<UserProfile> salvarEndereco(Address endereco);

  Future<UserProfile> removerEndereco(String id);

  Future<UserProfile> definirEnderecoPrincipal(String id);

  /// Esqueci minha senha, passo 1: o backend manda um código de 6 dígitos
  /// para o e-mail (válido por 15 minutos). Termina sem erro mesmo se não
  /// houver conta com esse e-mail — o servidor não revela quem é cliente.
  Future<void> solicitarCodigoSenha(String email);

  /// Esqueci minha senha, passo 2: confere o código e grava a nova senha.
  /// Lança [UserProfileException] com a mensagem do backend (código
  /// incorreto, expirado, muitas tentativas...).
  Future<void> redefinirSenha({required String email, required String codigo, required String novaSenha});
}

/// Implementação em memória, usada enquanto não há integração real.
/// Mantém o estado entre chamadas (e entre logins), como um servidor.
///
/// Regras que o backend real também deve seguir:
/// - no máximo um endereço principal;
/// - o primeiro endereço salvo vira principal automaticamente;
/// - apagar o principal promove o primeiro dos que sobraram.
class MockUserProfileService implements UserProfileService {
  MockUserProfileService({
    this.atraso = const Duration(milliseconds: 500),
    UserProfile? perfilInicial,
  }) : _perfil = perfilInicial ?? _perfilDemo;

  /// Latência simulada. Zero nos testes: um `Future.delayed` não termina
  /// sozinho dentro do relógio falso do `testWidgets`.
  final Duration atraso;

  UserProfile _perfil;
  int _proximoId = 100;

  static const _perfilDemo = UserProfile(
    id: 'cliente-demo',
    name: 'Ana Souza',
    phone: '(16) 98888-1234',
    email: 'ana.souza@exemplo.com',
    addresses: [
      Address(
        id: 'end-1',
        street: 'Rua das Palmeiras',
        number: '120',
        complement: 'Apto 21',
        neighborhood: 'Jardim Itápolis',
        zipCode: '15900-000',
        isMain: true,
      ),
      Address(
        id: 'end-2',
        street: 'Avenida Florência',
        number: '455',
        neighborhood: 'Centro',
        zipCode: '15900-020',
      ),
    ],
  );

  Future<void> _latencia() async {
    if (atraso > Duration.zero) await Future.delayed(atraso);
  }

  @override
  Future<UserProfile?> entrar(String email, String senha) async {
    await _latencia();
    // Sem cadastro real: qualquer credencial entra como o cliente demo,
    // com o e-mail digitado.
    _perfil = _perfil.copyWith(email: email);
    return _perfil;
  }

  // Mantém o perfil: o mock simula um servidor, que não esquece o cliente.
  @override
  void sair() {}

  @override
  Future<UserProfile> cadastrar({
    required String name,
    required String email,
    required String phone,
    required String senha,
  }) async {
    await _latencia();
    _perfil = UserProfile(id: 'cliente-${_proximoId++}', name: name, phone: phone, email: email);
    return _perfil;
  }

  @override
  Future<UserProfile?> obterPerfil() async {
    await _latencia();
    return _perfil;
  }

  @override
  Future<UserProfile> atualizarDados({required String name, required String email, required String phone}) async {
    await _latencia();
    _perfil = _perfil.copyWith(name: name, email: email, phone: phone);
    return _perfil;
  }

  @override
  Future<UserProfile> salvarEndereco(Address endereco) async {
    await _latencia();
    final lista = [..._perfil.addresses];

    if (endereco.id == null) {
      lista.add(endereco.copyWith(id: 'end-${_proximoId++}', isMain: endereco.isMain || lista.isEmpty));
    } else {
      final indice = lista.indexWhere((e) => e.id == endereco.id);
      if (indice < 0) throw const UserProfileException('Este endereço não existe mais. Atualize a página.');
      // O principal não pode ser "desmarcado" direto — só trocando por outro.
      lista[indice] = endereco.copyWith(isMain: endereco.isMain || lista[indice].isMain);
    }

    final salvo = endereco.id ?? lista.last.id;
    final principal = lista.firstWhere((e) => e.id == salvo).isMain ? salvo : _perfil.mainAddressId;
    _perfil = _perfil.copyWith(addresses: _comPrincipal(lista, principal));
    return _perfil;
  }

  @override
  Future<UserProfile> removerEndereco(String id) async {
    await _latencia();
    final lista = _perfil.addresses.where((e) => e.id != id).toList();
    final principal = _perfil.mainAddressId == id ? (lista.isEmpty ? null : lista.first.id) : _perfil.mainAddressId;
    _perfil = _perfil.copyWith(addresses: _comPrincipal(lista, principal));
    return _perfil;
  }

  @override
  Future<UserProfile> definirEnderecoPrincipal(String id) async {
    await _latencia();
    if (!_perfil.addresses.any((e) => e.id == id)) {
      throw const UserProfileException('Este endereço não existe mais. Atualize a página.');
    }
    _perfil = _perfil.copyWith(addresses: _comPrincipal(_perfil.addresses, id));
    return _perfil;
  }

  /// Código aceito pelo mock no "Esqueci minha senha" (não há e-mail de verdade).
  static const codigoDemo = '123456';

  @override
  Future<void> solicitarCodigoSenha(String email) => _latencia();

  @override
  Future<void> redefinirSenha({required String email, required String codigo, required String novaSenha}) async {
    await _latencia();
    if (codigo != codigoDemo) throw const UserProfileException('Código incorreto. Confira o e-mail e tente de novo.');
  }

  List<Address> _comPrincipal(List<Address> lista, String? idPrincipal) =>
      [for (final e in lista) e.copyWith(isMain: e.id == idPrincipal)];
}

/// Perfil e endereços salvos pela API (`/api/app/me` e `/api/app/enderecos`).
/// Toda escrita devolve o perfil completo, já com as regras do servidor
/// aplicadas (ex.: qual endereço virou o principal).
class ApiUserProfileService implements UserProfileService {
  ApiUserProfileService(this._api);

  final ApiClient _api;

  @override
  Future<UserProfile?> entrar(String email, String senha) async {
    _api.definirCredenciais(email.trim(), senha);
    try {
      return _perfilDaApi(await _api.get('/app/me'));
    } on ApiException catch (erro) {
      _api.limparCredenciais();
      if (erro.naoAutorizado) return null;
      rethrow;
    }
  }

  @override
  Future<UserProfile> cadastrar({
    required String name,
    required String email,
    required String phone,
    required String senha,
  }) async {
    final perfil = await _executar(() => _api.post('/app/cadastro', {
          'nome': name,
          'email': email.trim(),
          'telefone': phone,
          'senha': senha,
        }));
    // A conta nasceu: as próximas chamadas já vão autenticadas com ela.
    _api.definirCredenciais(perfil.email, senha);
    return perfil;
  }

  @override
  void sair() => _api.limparCredenciais();

  @override
  Future<UserProfile?> obterPerfil() => _executar(() => _api.get('/app/me'));

  @override
  Future<UserProfile> atualizarDados({required String name, required String email, required String phone}) async {
    final perfil = await _executar(() => _api.put('/app/me', {'nome': name, 'email': email.trim(), 'telefone': phone}));
    _api.atualizarEmail(perfil.email);
    return perfil;
  }

  @override
  Future<UserProfile> salvarEndereco(Address endereco) {
    final corpo = {
      'logradouro': endereco.street,
      'numero': endereco.number,
      'complemento': endereco.complement,
      'bairro': endereco.neighborhood,
      'cep': endereco.zipCode,
      'cidade': endereco.city,
      'estado': endereco.state,
      'principal': endereco.isMain,
    };
    final id = endereco.id;
    return _executar(() => id == null ? _api.post('/app/enderecos', corpo) : _api.put('/app/enderecos/$id', corpo));
  }

  @override
  Future<UserProfile> removerEndereco(String id) => _executar(() => _api.delete('/app/enderecos/$id'));

  @override
  Future<UserProfile> definirEnderecoPrincipal(String id) => _executar(() => _api.put('/app/enderecos/$id/principal'));

  @override
  Future<void> solicitarCodigoSenha(String email) =>
      _semPerfil(() => _api.post('/app/senha/esqueci', {'email': email.trim()}));

  @override
  Future<void> redefinirSenha({required String email, required String codigo, required String novaSenha}) =>
      _semPerfil(() => _api.post('/app/senha/redefinir', {
            'email': email.trim(),
            'codigo': codigo,
            'novaSenha': novaSenha,
          }));

  /// Chamadas anônimas que não devolvem perfil: mesmo tratamento de erro
  /// de [_executar].
  Future<void> _semPerfil(Future<dynamic> Function() chamada) async {
    try {
      await chamada();
    } on ApiException catch (erro) {
      if (erro.statusCode == null) rethrow;
      throw UserProfileException(erro.message);
    }
  }

  /// Erros da API viram [UserProfileException], cuja mensagem o
  /// `AuthProvider` mostra na tela.
  Future<UserProfile> _executar(Future<dynamic> Function() chamada) async {
    try {
      return _perfilDaApi(await chamada());
    } on ApiException catch (erro) {
      if (erro.statusCode == null) rethrow; // sem conexão: o provider mostra a mensagem genérica
      throw UserProfileException(erro.naoAutorizado ? 'Sua sessão expirou. Entre novamente.' : erro.message);
    }
  }

  UserProfile _perfilDaApi(dynamic data) {
    final json = data as Map<String, dynamic>;
    return UserProfile(
      id: json['id'].toString(),
      name: json['nome'] as String? ?? '',
      phone: json['telefone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      addresses: [
        for (final e in (json['enderecos'] as List<dynamic>? ?? const []).cast<Map<String, dynamic>>())
          Address(
            id: e['id'].toString(),
            street: e['logradouro'] as String? ?? '',
            number: e['numero'] as String? ?? '',
            complement: e['complemento'] as String? ?? '',
            neighborhood: e['bairro'] as String? ?? '',
            zipCode: e['cep'] as String? ?? '',
            city: e['cidade'] as String? ?? '',
            state: e['estado'] as String? ?? '',
            isMain: e['principal'] as bool? ?? false,
          ),
      ],
    );
  }
}
