import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_text_styles.dart';
import '../models/payment_method.dart';

/// Card selecionável de forma de pagamento (ícone + nome), usado em uma
/// fileira de três (Dinheiro, Cartão, Pix). Selecionado: borda, ícone e
/// texto em verde — só a cor já indica a seleção, sem ícone extra de
/// check.
class PaymentMethodCard extends StatelessWidget {
  const PaymentMethodCard({
    super.key,
    required this.method,
    required this.selected,
    required this.onTap,
  });

  final PaymentMethod method;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.success.withValues(alpha: 0.08) : AppColors.inputBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.success : AppColors.inputBorder,
              width: selected ? 2 : 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                method.icon,
                size: 26,
                color: selected ? AppColors.success : AppColors.textLabel,
              ),
              const SizedBox(height: 6),
              Text(
                method.label,
                style: AppTextStyles.chip(selecionado: false).copyWith(
                  color: selected ? AppColors.success : AppColors.textLabel,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
