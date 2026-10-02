import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/navigation_provider.dart';

/// Atalhos de navegação entre abas usados pelas telas.
class AppNavigation {
  AppNavigation._();

  /// Vai para [aba] a partir de qualquer tela.
  ///
  /// Se a tela principal já está na pilha, só troca a aba selecionada e
  /// fecha o que estiver por cima dela (detalhe, checkout, confirmação) —
  /// sem recriar as abas, então nada é recarregado. Se não está (telas
  /// abertas isoladamente, como nos testes), navega pela rota da aba.
  static void irParaAba(BuildContext context, AppTab aba) => acaoIrParaAba(context, aba)();

  /// Igual a [irParaAba], mas captura o Navigator e o provider agora e
  /// devolve a ação para executar depois. Necessário quando o `context`
  /// pode não existir mais na hora do toque — ex.: o "VER CARRINHO" da
  /// SnackBar mostrada pela tela de detalhe, que já foi fechada.
  static VoidCallback acaoIrParaAba(BuildContext context, AppTab aba) {
    final navigator = Navigator.of(context);
    final navegacao = Provider.of<NavigationProvider?>(context, listen: false);

    return () {
      try {
        if (navegacao != null && navegacao.shellMontado) {
          navegacao.selecionar(aba);
          // O shell é sempre a primeira rota enquanto há sessão (o login
          // o abre com pushReplacement e o logout limpa a pilha).
          navigator.popUntil((route) => route.isFirst);
        } else {
          navigator.pushNamedAndRemoveUntil(aba.rota, (_) => false);
        }
      } catch (erro, stack) {
        debugPrint('Falha ao navegar para a aba ${aba.name}: $erro\n$stack');
        navigator.pushNamedAndRemoveUntil(AppTab.produtos.rota, (_) => false);
      }
    };
  }
}
