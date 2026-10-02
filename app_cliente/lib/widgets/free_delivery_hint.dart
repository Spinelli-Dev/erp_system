import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_text_styles.dart';
import '../core/formatters.dart';
import '../models/delivery_fee_rule.dart';

/// "Faltam R$ 10,20 para a entrega grátis" / "Você ganhou entrega grátis!"
/// — mostrado no carrinho e na finalização quando os gestores definiram
/// um pedido mínimo para entrega grátis. Sem essa regra, não ocupa espaço.
class FreeDeliveryHint extends StatelessWidget {
  const FreeDeliveryHint({super.key, required this.regra, required this.subtotal});

  final DeliveryFeeRule regra;
  final double subtotal;

  @override
  Widget build(BuildContext context) {
    if (!regra.temEntregaGratis || subtotal <= 0) return const SizedBox.shrink();

    final falta = regra.faltaParaGratis(subtotal);
    final ganhou = falta == null;

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(
            ganhou ? Icons.check_circle_outline : Icons.local_shipping_outlined,
            size: 15,
            color: ganhou ? AppColors.success : AppColors.textMuted,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              ganhou ? 'Você ganhou entrega grátis!' : 'Faltam ${formatarPreco(falta)} para a entrega grátis',
              style: AppTextStyles.subtituloLogin(size: 12.5).copyWith(
                color: ganhou ? AppColors.success : AppColors.textMuted,
                fontWeight: ganhou ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
