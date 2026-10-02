import '../models/franchise_info.dart';
import '../models/payment_method.dart';
import 'formatters.dart';

/// Monta o texto de instruções mostrado na confirmação do pedido,
/// conforme a forma de pagamento escolhida.
String gerarInstrucoesPagamento({
  required PaymentMethod method,
  required double total,
  required FranchiseInfo franquia,
}) {
  final totalFormatado = formatarPreco(total);
  return switch (method) {
    PaymentMethod.cash => 'Pague $totalFormatado em dinheiro no momento da entrega ou retirada.',
    PaymentMethod.card =>
      'Leve seu cartão (débito ou crédito) na retirada, ou avise ao entregador — a maquininha vai junto.',
    PaymentMethod.pix =>
      'Chave Pix: ${franquia.pixKey}\nValor: $totalFormatado\nEnvie o comprovante pelo WhatsApp ${franquia.phoneNumber} para agilizar seu pedido.',
  };
}
