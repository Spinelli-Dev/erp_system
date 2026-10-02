import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Estilos de texto espelhando as classes .titulo-banner, .titulo-login,
/// .label-login etc. do painel web (fonte Inter).
class AppTextStyles {
  AppTextStyles._();

  static TextStyle tituloBanner({double size = 26}) => GoogleFonts.inter(
        color: Colors.white,
        fontSize: size,
        fontWeight: FontWeight.w800,
      );

  static TextStyle subtituloBanner({double size = 15}) => GoogleFonts.inter(
        color: Colors.white.withValues(alpha: 0.75),
        fontSize: size,
        fontWeight: FontWeight.w500,
      );

  static TextStyle textoSistema = GoogleFonts.inter(
    color: Colors.white.withValues(alpha: 0.55),
    fontSize: 14,
  );

  static TextStyle textoBoasVindas = GoogleFonts.inter(
    color: Colors.white.withValues(alpha: 0.65),
    fontSize: 15,
    fontWeight: FontWeight.w600,
  );

  static TextStyle tituloLogin({double size = 24}) => GoogleFonts.inter(
        color: AppColors.textDark,
        fontSize: size,
        fontWeight: FontWeight.w800,
      );

  static TextStyle subtituloLogin({double size = 13}) => GoogleFonts.inter(
        color: AppColors.textMuted,
        fontSize: size,
      );

  static TextStyle label({double size = 12}) => GoogleFonts.inter(
        color: AppColors.textLabel,
        fontSize: size,
        fontWeight: FontWeight.w600,
      );

  static TextStyle input = GoogleFonts.inter(
    color: AppColors.textDark,
    fontSize: 14,
  );

  static TextStyle linkSenha({double size = 13}) => GoogleFonts.inter(
        color: AppColors.primary,
        fontSize: size,
        fontWeight: FontWeight.w500,
      );

  static TextStyle botao = GoogleFonts.inter(
    color: Colors.white,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.3,
  );

  static TextStyle rodape({double size = 11}) => GoogleFonts.inter(
        color: AppColors.textMuted,
        fontSize: size,
      );

  static TextStyle erro = GoogleFonts.inter(
    color: AppColors.errorText,
    fontSize: 13,
    fontWeight: FontWeight.w500,
  );

  // --- Telas de produtos ---

  static TextStyle appBarTitulo = GoogleFonts.inter(
    color: Colors.white,
    fontSize: 17,
    fontWeight: FontWeight.w800,
  );

  static TextStyle chip({required bool selecionado}) => GoogleFonts.inter(
        color: selecionado ? Colors.white : AppColors.textLabel,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      );

  static TextStyle nomeProduto = GoogleFonts.inter(
    color: AppColors.textDark,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  static TextStyle descricaoProduto = GoogleFonts.inter(
    color: AppColors.textMuted,
    fontSize: 11.5,
    fontWeight: FontWeight.w400,
    height: 1.3,
  );

  static TextStyle precoProduto = GoogleFonts.inter(
    color: AppColors.primary,
    fontSize: 15,
    fontWeight: FontWeight.w800,
  );

  static TextStyle tituloSecao({double size = 18}) => GoogleFonts.inter(
        color: AppColors.textDark,
        fontSize: size,
        fontWeight: FontWeight.w800,
      );
}
