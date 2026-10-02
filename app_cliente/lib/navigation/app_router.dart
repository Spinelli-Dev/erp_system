import 'package:flutter/material.dart';

import '../providers/auth_provider.dart';
import '../providers/navigation_provider.dart';
import '../screens/login_screen.dart';
import 'main_shell.dart';

/// Resolve as rotas nomeadas do app, com a verificação de login.
///
/// - `/login` abre o login.
/// - As rotas das abas (`/produtos`, `/carrinho`, `/pedidos`, `/perfil`)
///   abrem a [MainShell] já na aba certa — é o que permite deep link
///   (ex.: abrir o app direto em "Meus Pedidos"). Sem sessão, caem no
///   login, que volta para a mesma aba depois de entrar.
/// - `/` e qualquer rota desconhecida vão para a aba de produtos (ou
///   login), em vez de estourar erro de rota inexistente.
class AppRouter {
  AppRouter(this._auth);

  static const login = '/login';

  final AuthProvider _auth;

  Route<dynamic> gerarRota(RouteSettings settings) {
    final nome = settings.name;

    if (nome == login) {
      final destino = settings.arguments is String ? settings.arguments as String : null;
      return _rotaLogin(destino: destino);
    }

    var aba = AppTab.daRota(nome);
    if (aba == null) {
      if (nome != '/') debugPrint('Rota desconhecida "$nome" — redirecionando para a tela inicial.');
      aba = AppTab.produtos;
    }

    if (!_auth.isLoggedIn) return _rotaLogin(destino: aba.rota);

    return PageRouteBuilder(
      settings: RouteSettings(name: aba.rota),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, __, ___) => MainShell(abaInicial: aba!),
      transitionsBuilder: (_, animacao, __, child) => FadeTransition(opacity: animacao, child: child),
    );
  }

  /// Uma única rota inicial (e não a pilha `/`, `/pedidos`… que o Flutter
  /// monta por padrão a partir do caminho), para o shell ser sempre a
  /// primeira rota — `AppNavigation` depende disso.
  List<Route<dynamic>> gerarRotasIniciais(String nomeInicial) => [gerarRota(RouteSettings(name: nomeInicial))];

  Route<dynamic> _rotaLogin({String? destino}) {
    return MaterialPageRoute(
      settings: const RouteSettings(name: login),
      builder: (_) => LoginScreen(destino: destino),
    );
  }
}
