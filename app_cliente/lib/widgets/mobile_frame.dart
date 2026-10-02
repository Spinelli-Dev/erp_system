import 'package:flutter/material.dart';

import '../core/app_colors.dart';

/// Moldura que trava a largura do app em tamanho de celular (430px) e
/// centraliza tudo numa faixa cinza neutra quando a janela é mais larga
/// que isso — Chrome de desktop, janela do Windows redimensionada etc.
///
/// É aplicada uma única vez, em [MaterialApp.builder] (ver `main.dart`),
/// para envolver o `Navigator` inteiro: assim toda tela nova (e todo
/// SnackBar/diálogo, que também entram pelo `child` do builder) já nasce
/// respeitando a largura de celular automaticamente, sem cada tela
/// precisar reimplementar essa restrição por conta própria — foi
/// justamente esquecer disso na tela de produtos que fez ela esticar
/// como uma página de site.
class MobileFrame extends StatelessWidget {
  const MobileFrame({super.key, required this.child});

  final Widget child;

  static const double maxWidth = 430;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFE9EAEC),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: maxWidth),
          child: ColoredBox(
            color: AppColors.background,
            child: child,
          ),
        ),
      ),
    );
  }
}
