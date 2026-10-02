import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import 'skeleton_box.dart';

/// Card "fantasma" exibido no lugar do [ProductCard] enquanto o cardápio
/// ainda está carregando, no mesmo formato do card real para a transição
/// ficar suave quando os dados chegam.
class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: const Padding(
        padding: EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: SkeletonBox(borderRadius: 12)),
            SizedBox(height: 10),
            SizedBox(height: 12, child: SkeletonBox()),
            SizedBox(height: 6),
            SizedBox(width: 80, height: 10, child: SkeletonBox()),
            SizedBox(height: 10),
            SizedBox(width: 60, height: 14, child: SkeletonBox()),
          ],
        ),
      ),
    );
  }
}
