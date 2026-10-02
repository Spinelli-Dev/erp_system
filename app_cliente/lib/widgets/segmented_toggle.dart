import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_text_styles.dart';

/// Alternador entre duas opções mutuamente exclusivas (ex.: tipo de
/// entrega), no estilo abas: fundo cinza claro, opção selecionada em
/// vermelho da marca — mesma lógica de estado do [CategoryChip], só que
/// para exatamente duas opções lado a lado ocupando a largura toda.
class SegmentedToggle<T> extends StatelessWidget {
  const SegmentedToggle({
    super.key,
    required this.options,
    required this.labels,
    required this.selected,
    required this.onChanged,
  }) : assert(options.length == 2, 'SegmentedToggle é para exatamente duas opções');

  final List<T> options;
  final List<String> labels;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder, width: 1.5),
      ),
      child: Row(
        children: List.generate(options.length, (index) {
          final opcao = options[index];
          final ativo = opcao == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(opcao),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                alignment: Alignment.center,
                margin: EdgeInsets.only(left: index == 0 ? 0 : 4),
                decoration: BoxDecoration(
                  color: ativo ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  labels[index],
                  textAlign: TextAlign.center,
                  style: AppTextStyles.chip(selecionado: ativo),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
