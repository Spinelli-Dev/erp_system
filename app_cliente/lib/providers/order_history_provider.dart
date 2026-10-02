import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter/foundation.dart';

import '../models/date_filter.dart';
import '../models/order_confirmation.dart';
import '../services/order_service.dart';

/// Histórico de pedidos do cliente e o filtro de período escolhido na aba
/// "Meus Pedidos".
///
/// Com [service] (API configurada), [carregar] traz todos os pedidos do
/// cliente do backend — com o status atualizado pelos gestores. Sem ele
/// (modo mock), guarda só os pedidos feitos nesta sessão, em memória.
class OrderHistoryProvider extends ChangeNotifier {
  /// [relogio] define o "agora" usado pelos filtros de período — os testes
  /// passam uma data fixa para não dependerem do dia em que rodam.
  OrderHistoryProvider({OrderHistoryService? service, DateTime Function()? relogio})
      : _service = service,
        _relogio = relogio ?? DateTime.now;

  static const filtroPadrao = DateFilter.last7Days;

  final OrderHistoryService? _service;
  final DateTime Function() _relogio;
  final List<OrderConfirmation> _pedidos = [];

  bool _carregando = false;
  String? _erro;
  bool _descartado = false;

  /// Muda a cada [limpar] (logout): uma busca que termine depois disso é
  /// do cliente que saiu e é descartada.
  int _geracao = 0;

  DateFilter _filtro = filtroPadrao;
  DateTimeRange? _periodoPersonalizado;

  /// Mais recentes primeiro.
  List<OrderConfirmation> get pedidos => List.unmodifiable(_pedidos.reversed);

  bool get isEmpty => _pedidos.isEmpty;

  /// Uma busca no backend está em andamento.
  bool get carregando => _carregando;

  /// Mensagem da última busca que falhou (`null` se deu certo).
  String? get erro => _erro;

  /// Busca os pedidos no backend (ao abrir a aba e no "puxar para
  /// atualizar"). Sem serviço, não faz nada. Se falhar, mantém a lista
  /// que já estava na tela e guarda a mensagem em [erro].
  Future<void> carregar() async {
    final servico = _service;
    if (servico == null || _carregando) return;

    final geracao = _geracao;
    _carregando = true;
    _erro = null;
    notifyListeners();
    try {
      final recebidos = await servico.buscarPedidos();
      if (_descartado || geracao != _geracao) return;
      // A API manda os mais recentes primeiro; aqui a lista fica em ordem
      // de criação (ver [pedidos]).
      _pedidos
        ..clear()
        ..addAll(recebidos.reversed);
    } catch (_) {
      if (_descartado || geracao != _geracao) return;
      _erro = 'Não foi possível carregar seus pedidos. Verifique sua conexão.';
    }
    _carregando = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _descartado = true;
    super.dispose();
  }

  DateFilter get filtro => _filtro;

  /// Só tem valor quando [filtro] é [DateFilter.custom].
  DateTimeRange? get periodoPersonalizado => _periodoPersonalizado;

  /// [pedidos] restritos ao período do [filtro] atual, mais recentes primeiro.
  List<OrderConfirmation> get pedidosFiltrados {
    final agora = _relogio();
    return pedidos
        .where((p) => _filtro.inclui(p.orderDate, agora: agora, periodo: _periodoPersonalizado))
        .toList();
  }

  void adicionar(OrderConfirmation pedido) {
    _pedidos.add(pedido);
    notifyListeners();
  }

  /// Para [DateFilter.custom], use [selecionarPeriodo].
  void selecionarFiltro(DateFilter filtro) {
    assert(filtro != DateFilter.custom, 'Use selecionarPeriodo para o filtro personalizado.');
    if (filtro == _filtro) return;
    _filtro = filtro;
    _periodoPersonalizado = null;
    notifyListeners();
  }

  void selecionarPeriodo(DateTimeRange periodo) {
    _filtro = DateFilter.custom;
    _periodoPersonalizado = periodo;
    notifyListeners();
  }

  /// Volta ao filtro padrão — chamado quando o usuário sai da aba
  /// "Meus Pedidos" e no logout.
  void resetarFiltro() {
    if (_filtro == filtroPadrao) return;
    _filtro = filtroPadrao;
    _periodoPersonalizado = null;
    notifyListeners();
  }

  /// Chamado no logout: o histórico é da sessão do cliente que saiu.
  void limpar() {
    _pedidos.clear();
    _erro = null;
    _carregando = false;
    _geracao++;
    _filtro = filtroPadrao;
    _periodoPersonalizado = null;
    notifyListeners();
  }
}
