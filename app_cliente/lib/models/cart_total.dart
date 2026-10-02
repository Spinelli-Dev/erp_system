/// Resumo de valores do carrinho, pronto para o rodapé fixo da tela de
/// carrinho (subtotal, taxa de entrega e total já calculado).
class CartTotal {
  const CartTotal({required this.subtotal, this.taxaEntrega = 0});

  final double subtotal;
  final double taxaEntrega;

  double get total => subtotal + taxaEntrega;
}
