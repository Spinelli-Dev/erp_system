import 'package:flutter/material.dart';

/// Forma de pagamento escolhida pelo cliente.
enum PaymentMethod { cash, card, pix }

extension PaymentMethodDisplay on PaymentMethod {
  String get label => switch (this) {
        PaymentMethod.cash => 'Dinheiro',
        PaymentMethod.card => 'Cartão',
        PaymentMethod.pix => 'Pix',
      };

  IconData get icon => switch (this) {
        PaymentMethod.cash => Icons.payments_outlined,
        PaymentMethod.card => Icons.credit_card_outlined,
        PaymentMethod.pix => Icons.qr_code_2_outlined,
      };
}
