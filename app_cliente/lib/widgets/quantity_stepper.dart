import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_text_styles.dart';

/// Seletor de quantidade (-, N, +), reutilizado na tela de detalhes do
/// produto e na tela de carrinho — mesmo visual nas duas, só em tamanhos
/// diferentes ([compact]).
///
/// [onDecrement] é opcional: passe `null` quando a quantidade já estiver
/// no mínimo permitido (o botão "-" fica visualmente desabilitado e para
/// de responder a toques). É assim que o carrinho trava a quantidade
/// mínima em 1 — a remoção do item vira uma ação separada, só pelo botão
/// de lixeira, para o usuário não perder o produto sem querer ao tocar
/// demais no "-".
///
/// O mesmo vale para [onIncrement]: `null` trava o "+" (ex.: o carrinho já
/// tem todo o estoque do produto). Com [avisoLimite], tocar no "+" travado
/// mostra esse texto num balão, para o cliente entender por que não sobe.
///
/// Quando [processando] é `true`, um spinner aparece sobreposto aos
/// botões (que ficam invisíveis e inativos, mas continuam no layout) —
/// usado no carrinho enquanto a alteração de quantidade está sendo
/// "sincronizada" (ver `CartProvider.updateQuantity`). Manter o Row
/// sempre presente, em vez de trocá-lo por um widget menor, evita que o
/// componente mude de tamanho ao alternar entre os dois estados.
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.quantity,
    required this.onIncrement,
    this.onDecrement,
    this.avisoLimite,
    this.processando = false,
    this.compact = false,
  });

  final int quantity;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;
  final String? avisoLimite;
  final bool processando;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final altura = compact ? 34.0 : 52.0;
    final larguraBotao = compact ? 28.0 : 36.0;
    final larguraNumero = compact ? 24.0 : 28.0;

    return Container(
      height: altura,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.inputBorder, width: 1.5),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Opacity(
            opacity: processando ? 0 : 1,
            child: IgnorePointer(
              ignoring: processando,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildBotao(Icons.remove, onDecrement, larguraBotao, altura),
                  SizedBox(
                    width: larguraNumero,
                    child: Text('$quantity', textAlign: TextAlign.center, style: AppTextStyles.nomeProduto),
                  ),
                  _buildBotaoMais(larguraBotao, altura),
                ],
              ),
            ),
          ),
          if (processando)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            ),
        ],
      ),
    );
  }

  Widget _buildBotaoMais(double largura, double altura) {
    final botao = _buildBotao(Icons.add, onIncrement, largura, altura);
    final aviso = avisoLimite;
    if (onIncrement != null || aviso == null) return botao;
    // Botão desabilitado não recebe toque; o Tooltip em volta recebe.
    return Tooltip(
      message: aviso,
      triggerMode: TooltipTriggerMode.tap,
      showDuration: const Duration(seconds: 2),
      child: botao,
    );
  }

  Widget _buildBotao(IconData icon, VoidCallback? onTap, double largura, double altura) {
    return SizedBox(
      width: largura,
      height: altura,
      child: IconButton(
        padding: EdgeInsets.zero,
        // Sem isso, o IconButton insiste no alvo de toque mínimo (~48px)
        // do Material e estoura o SizedBox mais estreito ao redor dele.
        constraints: const BoxConstraints(),
        onPressed: onTap,
        icon: Icon(
          icon,
          size: compact ? 15 : 18,
          color: onTap == null ? AppColors.textMuted.withValues(alpha: 0.5) : AppColors.primary,
        ),
      ),
    );
  }
}
