import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_text_styles.dart';

/// Caixa de erro de formulário (fundo rosado, borda e texto vermelhos) —
/// mesmo alerta da tela de login, usado nos formulários do Perfil.
class FormErrorAlert extends StatelessWidget {
  const FormErrorAlert({super.key, required this.mensagem});

  final String mensagem;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.errorBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.errorBorder),
      ),
      child: Text(mensagem, textAlign: TextAlign.center, style: AppTextStyles.erro),
    );
  }
}
