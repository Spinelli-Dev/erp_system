import 'package:flutter/foundation.dart';

import '../models/address.dart';
import '../models/user_profile.dart';
import '../services/user_profile_service.dart';

/// Sessão do cliente logado, compartilhada pelo app via Provider.
///
/// É a fonte única para "tem alguém logado?" — as rotas das abas
/// (ver `navigation/app_router.dart`) consultam [isLoggedIn] antes de
/// abrir — e para os dados do cliente: a aba Perfil lê e edita [usuario]
/// daqui, e a finalização do pedido pré-preenche contato e endereço
/// principal a partir dele. Toda alteração passa pelo serviço (backend)
/// e só entra aqui depois de confirmada, já com a resposta dele.
///
/// Assim como os outros providers, guarda tudo em memória: fechar o app
/// desloga. Para manter a sessão entre aberturas, persista as credenciais
/// com `flutter_secure_storage` (nunca em `shared_preferences`).
class AuthProvider extends ChangeNotifier {
  AuthProvider({UserProfileService? service}) : _service = service ?? MockUserProfileService();

  final UserProfileService _service;

  UserProfile? _usuario;

  UserProfile? get usuario => _usuario;

  bool get isLoggedIn => _usuario != null;

  /// Retorna `null` em caso de sucesso, ou a mensagem de erro para
  /// mostrar na tela de login — mesmo contrato de `LoginScreen.onLogin`.
  Future<String?> login(String email, String senha) async {
    try {
      final perfil = await _service.entrar(email, senha);
      if (perfil == null) return 'E-mail ou senha incorretos.';
      _usuario = perfil;
      notifyListeners();
      return null;
    } catch (_) {
      return 'Não foi possível entrar. Verifique sua conexão e tente novamente.';
    }
  }

  /// Cria a conta e já deixa o cliente logado. Mesmo contrato de [login]:
  /// `null` em caso de sucesso, ou a mensagem de erro para a tela.
  Future<String?> cadastrar({
    required String name,
    required String email,
    required String phone,
    required String senha,
  }) async {
    try {
      _usuario = await _service.cadastrar(name: name, email: email, phone: phone, senha: senha);
      notifyListeners();
      return null;
    } on UserProfileException catch (erro) {
      return erro.message;
    } catch (_) {
      return 'Não foi possível criar sua conta. Verifique sua conexão e tente novamente.';
    }
  }

  /// Esqueci minha senha, passo 1 (pede o código por e-mail). `null` em
  /// caso de sucesso, ou a mensagem de erro para a tela.
  Future<String?> solicitarCodigoSenha(String email) async {
    try {
      await _service.solicitarCodigoSenha(email);
      return null;
    } on UserProfileException catch (erro) {
      return erro.message;
    } catch (_) {
      return 'Não foi possível enviar o código. Verifique sua conexão e tente novamente.';
    }
  }

  /// Esqueci minha senha, passo 2 (código + nova senha). Não abre sessão:
  /// o cliente volta ao login e entra com a senha nova.
  Future<String?> redefinirSenha({required String email, required String codigo, required String novaSenha}) async {
    try {
      await _service.redefinirSenha(email: email, codigo: codigo, novaSenha: novaSenha);
      return null;
    } on UserProfileException catch (erro) {
      return erro.message;
    } catch (_) {
      return 'Não foi possível alterar a senha. Verifique sua conexão e tente novamente.';
    }
  }

  void logout() {
    _service.sair();
    _usuario = null;
    notifyListeners();
  }

  /// Busca o perfil de novo no backend (ex.: ao abrir a aba Perfil), para
  /// refletir mudanças feitas em outro dispositivo. Em caso de falha,
  /// mantém os dados que já estavam na tela.
  Future<String?> recarregarPerfil() => _executar(() async {
        final perfil = await _service.obterPerfil();
        return perfil ?? _usuario!;
      });

  Future<String?> atualizarDados({required String name, required String email, required String phone}) =>
      _executar(() => _service.atualizarDados(name: name, email: email, phone: phone));

  /// Cria (sem `id`) ou atualiza (com `id`) um endereço salvo.
  Future<String?> salvarEndereco(Address endereco) => _executar(() => _service.salvarEndereco(endereco));

  Future<String?> removerEndereco(String id) => _executar(() => _service.removerEndereco(id));

  Future<String?> definirEnderecoPrincipal(String id) => _executar(() => _service.definirEnderecoPrincipal(id));

  /// Roda uma operação no serviço e, se der certo, troca [usuario] pela
  /// resposta. Retorna `null` em caso de sucesso ou a mensagem de erro.
  Future<String?> _executar(Future<UserProfile> Function() operacao) async {
    if (_usuario == null) return 'Sua sessão expirou. Entre novamente.';
    try {
      final atualizado = await operacao();
      // O usuário pode ter saído enquanto a requisição corria.
      if (_usuario == null) return null;
      _usuario = atualizado;
      notifyListeners();
      return null;
    } on UserProfileException catch (erro) {
      return erro.message;
    } catch (_) {
      return 'Não foi possível salvar. Verifique sua conexão e tente novamente.';
    }
  }
}
