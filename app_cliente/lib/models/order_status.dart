/// Situação do pedido, espelhando o status da venda no backend — é o que
/// os gestores vão mudando no sistema web conforme o pedido anda.
enum OrderStatus { recebido, emPreparo, pago, saiuParaEntrega, concluido, cancelado }

extension OrderStatusDisplay on OrderStatus {
  String get label => switch (this) {
        OrderStatus.recebido => 'Confirmado',
        OrderStatus.emPreparo => 'Em preparo',
        OrderStatus.pago => 'Pago',
        OrderStatus.saiuParaEntrega => 'Saiu para entrega',
        OrderStatus.concluido => 'Concluído',
        OrderStatus.cancelado => 'Cancelado',
      };

  /// `StatusVenda` da API (ex.: "EmEntrega") → [OrderStatus].
  static OrderStatus daApi(String? valor) => switch (valor) {
        'EmProcessamento' => OrderStatus.emPreparo,
        'Paga' => OrderStatus.pago,
        'EmEntrega' => OrderStatus.saiuParaEntrega,
        'Concluida' => OrderStatus.concluido,
        'Cancelada' => OrderStatus.cancelado,
        _ => OrderStatus.recebido,
      };
}
