import 'package:flutter/material.dart';

import '../core/app_colors.dart';

/// Reproduz o fundo vermelho com círculos translúcidos usado no banner
/// de login do site (backend/wwwroot/assets/images/banner-sem-logo-*.png),
/// sem depender de um asset de imagem — assim ele se adapta a qualquer
/// tamanho de tela (mobile ou desktop).
class DecorativeBanner extends StatelessWidget {
  const DecorativeBanner({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryLight, AppColors.primaryDark],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned(top: -70, left: -60, child: _Circle(220)),
          const Positioned(top: 120, right: -70, child: _Circle(160)),
          const Positioned(bottom: 40, right: -50, child: _Circle(210)),
          const Positioned(bottom: -60, left: -40, child: _Circle(130)),
          child,
        ],
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  const _Circle(this.size);

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.07),
      ),
    );
  }
}
