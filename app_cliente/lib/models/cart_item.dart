import 'product.dart';

/// Um produto dentro do carrinho, com a quantidade escolhida pelo cliente.
class CartItem {
  CartItem({required this.product, this.quantity = 1});

  final Product product;
  int quantity;

  double get subtotal => product.price * quantity;
}
