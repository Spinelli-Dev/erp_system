import 'package:intl/intl.dart';

final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

/// Formata um valor em reais no padrão "R$ 24,90".
String formatarPreco(double valor) => _currencyFormat.format(valor);

/// Formata data e hora no padrão "23/09/2026 às 14:32".
///
/// Escrito na mão (em vez de `DateFormat` do pacote intl) porque um
/// padrão com nomes de mês/dia exigiria `initializeDateFormatting()` no
/// arranque do app para a localidade pt_BR — como aqui só usamos campos
/// numéricos, não vale a pena a dependência extra dessa inicialização.
String formatarDataHora(DateTime data) {
  String doisDigitos(int numero) => numero.toString().padLeft(2, '0');
  return '${doisDigitos(data.day)}/${doisDigitos(data.month)}/${data.year}'
      ' às ${doisDigitos(data.hour)}:${doisDigitos(data.minute)}';
}

/// Formata só a hora, no padrão "14:32".
String formatarHora(DateTime data) {
  String doisDigitos(int numero) => numero.toString().padLeft(2, '0');
  return '${doisDigitos(data.hour)}:${doisDigitos(data.minute)}';
}
