import 'package:flutter/material.dart' show DateTimeRange;

/// Período usado para filtrar a lista de "Meus Pedidos".
enum DateFilter {
  last7Days('Últimos 7 dias'),
  thisMonth('Este mês'),
  last3Months('Últimos 3 meses'),
  all('Todos'),
  custom('Personalizado');

  const DateFilter(this.label);

  final String label;

  /// Se [data] cai dentro do período, tendo [agora] como referência.
  /// [periodo] só é usado em [DateFilter.custom] (sem ele, nada é
  /// descartado).
  bool inclui(DateTime data, {required DateTime agora, DateTimeRange? periodo}) {
    final hoje = DateTime(agora.year, agora.month, agora.day);

    switch (this) {
      case DateFilter.last7Days:
        // Hoje + os 6 dias anteriores, contando desde a meia-noite.
        return !data.isBefore(hoje.subtract(const Duration(days: 6)));
      case DateFilter.thisMonth:
        return data.year == agora.year && data.month == agora.month;
      case DateFilter.last3Months:
        // DateTime normaliza mês <= 0 para o ano anterior.
        return !data.isBefore(DateTime(hoje.year, hoje.month - 3, hoje.day));
      case DateFilter.all:
        return true;
      case DateFilter.custom:
        if (periodo == null) return true;
        final inicio = DateTime(periodo.start.year, periodo.start.month, periodo.start.day);
        final fimExclusivo = DateTime(periodo.end.year, periodo.end.month, periodo.end.day + 1);
        return !data.isBefore(inicio) && data.isBefore(fimExclusivo);
    }
  }
}
