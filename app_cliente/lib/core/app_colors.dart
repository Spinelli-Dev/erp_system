import 'package:flutter/material.dart';

/// Paleta extraída da identidade visual do site Maxi Massas
/// (backend/wwwroot/css/componentes.css), reaproveitada no app do cliente.
class AppColors {
  AppColors._();

  /// Vermelho principal da marca (botões, links, destaque).
  static const primary = Color(0xFF9A1006);

  /// Tom mais escuro, usado no gradiente do banner e no estado pressionado.
  static const primaryDark = Color(0xFF6E0B04);

  /// Tom mais claro, usado no gradiente do banner.
  static const primaryLight = Color(0xFFB4160B);

  static const background = Color(0xFFFFFFFF);
  static const inputBackground = Color(0xFFF3F4F6);
  static const inputBorder = Color(0xFFE0E1E5);

  static const textDark = Color(0xFF111827);
  static const textLabel = Color(0xFF4B5563);
  static const textMuted = Color(0xFF9CA3AC);

  static const errorBackground = Color(0xFFF8D7DA);
  static const errorBorder = Color(0xFFF5C2C7);
  static const errorText = Color(0xFF842029);

  /// Fundo neutro do app (atrás dos cards), levemente acinzentado para os
  /// cards brancos se destacarem — mesmo tom usado como base do site.
  static const scaffoldBackground = Color(0xFFF9F9FA);

  static const cardBackground = Color(0xFFFFFFFF);
  static const cardBorder = Color(0xFFEEEFF1);
  static const cardShadow = Color(0x1A111827);

  /// Verde usado apenas para confirmações rápidas (ex.: item adicionado).
  static const success = Color(0xFF15803D);
}
