import 'package:flutter/foundation.dart';

/// Abas da barra de navegação inferior, na ordem em que aparecem. Cada
/// uma tem sua rota nomeada — é por ela que o app pode ser aberto direto
/// numa aba (deep link, ex.: `/pedidos`).
enum AppTab {
  produtos('/produtos'),
  carrinho('/carrinho'),
  pedidos('/pedidos'),
  perfil('/perfil');

  const AppTab(this.rota);

  final String rota;

  static AppTab? daRota(String? rota) {
    for (final aba in values) {
      if (aba.rota == rota) return aba;
    }
    return null;
  }
}

/// Aba selecionada na tela principal ([MainShell]), num provider global
/// para que qualquer tela — inclusive as empilhadas por cima das abas,
/// como detalhe do produto ou confirmação do pedido — consiga trocar de
/// aba sem precisar de referência ao shell (ver `AppNavigation`).
class NavigationProvider extends ChangeNotifier {
  AppTab _abaAtual = AppTab.produtos;
  int _shellsMontados = 0;

  AppTab get abaAtual => _abaAtual;

  /// Se existe um [MainShell] na pilha de rotas. Quando não existe (ex.:
  /// telas testadas isoladamente), trocar de aba vira navegar pela rota.
  bool get shellMontado => _shellsMontados > 0;

  void selecionar(AppTab aba) {
    if (aba == _abaAtual) return;
    _abaAtual = aba;
    notifyListeners();
  }

  /// Chamado no `initState` do shell. Não notifica: o próprio shell é
  /// quem observa [abaAtual], e ainda está sendo construído.
  void registrarShell(AppTab abaInicial) {
    _shellsMontados++;
    _abaAtual = abaInicial;
  }

  /// Contador (e não bool) porque, ao trocar um shell por outro, o novo
  /// é montado antes do antigo terminar de ser descartado.
  void removerShell() => _shellsMontados--;

  /// Volta para a aba inicial — usado no logout, para o próximo login não
  /// cair na aba em que o usuário anterior parou.
  void reset() {
    _abaAtual = AppTab.produtos;
    notifyListeners();
  }
}
