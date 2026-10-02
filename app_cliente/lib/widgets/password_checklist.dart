import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_text_styles.dart';
import '../core/validators.dart';

/// Requisitos da senha, sempre visíveis embaixo do campo, marcando cada
/// um conforme o cliente digita — ele sabe a regra antes de errar, em vez
/// de descobrir pela mensagem de erro.
class PasswordChecklist extends StatelessWidget {
  const PasswordChecklist({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final senha = controller.text;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final regra in regrasSenha) _Item(descricao: regra.descricao, atendida: regra.atendidaPor(senha)),
          ],
        );
      },
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({required this.descricao, required this.atendida});

  final String descricao;
  final bool atendida;

  @override
  Widget build(BuildContext context) {
    final cor = atendida ? AppColors.success : AppColors.textMuted;

    return Semantics(
      label: '$descricao: ${atendida ? 'atendido' : 'pendente'}',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              child: Icon(
                atendida ? Icons.check_circle : Icons.radio_button_unchecked,
                key: ValueKey(atendida),
                size: 16,
                color: cor,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              descricao,
              style: AppTextStyles.subtituloLogin(size: 12.5).copyWith(
                color: atendida ? AppColors.success : AppColors.textLabel,
                fontWeight: atendida ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
