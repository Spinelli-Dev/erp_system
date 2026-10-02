import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../core/app_text_styles.dart';
import '../core/formatters.dart';
import '../models/cart_item.dart';
import '../navigation/app_navigation.dart';
import '../providers/cart_provider.dart';
import '../providers/navigation_provider.dart';
import '../widgets/app_button.dart';
import '../widgets/product_image.dart';
import '../widgets/quantity_stepper.dart';
import '../widgets/free_delivery_hint.dart';
import 'checkout_screen.dart';

/// Aba "Carrinho" (ver `MainShell`): lista os itens adicionados (com seletor de
/// quantidade, subtotal e remoção por swipe ou botão) e mostra o resumo
/// de valores num rodapé fixo. "Finalizar Pedido" abre a [CheckoutScreen]
/// (tipo de entrega, endereço, pagamento) — a confirmação em si acontece
/// lá, não aqui.
///
/// Reaproveita as mesmas cores/tipografia/componentes da tela de produtos
/// ([AppColors], [AppTextStyles], [AppButton], [ProductImage],
/// [QuantityStepper]) para manter a coesão visual, e observa o mesmo
/// [CartProvider] que alimenta o badge do carrinho na AppBar — qualquer
/// mudança feita aqui (quantidade, remoção) já reflete lá também.
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();
    // O ScaffoldMessenger é único para o app inteiro (o MaterialApp cria
    // um só, compartilhado por todas as rotas) — então a SnackBar de
    // "produto adicionado ao carrinho" (mostrada na tela de produtos)
    // continua visível por cima daqui se o usuário navegar rápido demais.
    // `clearSnackBars()` (não `hideCurrentSnackBar()`) porque se o
    // usuário adicionou vários produtos rapidinho, pode haver mais de
    // uma mensagem na fila — só esconder a atual deixaria as próximas
    // aparecerem sozinhas em seguida, inclusive depois de sair daqui.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ScaffoldMessenger.of(context).clearSnackBars();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        automaticallyImplyLeading: false,
        title: Text('Seu Carrinho', style: AppTextStyles.appBarTitulo),
      ),
      body: Consumer<CartProvider>(
        builder: (context, cart, _) {
          if (cart.isEmpty) return _buildVazio(context);

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: cart.items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => _CartItemTile(item: cart.items[index], cart: cart),
                ),
              ),
              _buildRodape(cart),
            ],
          );
        },
      ),
    );
  }

  Widget _buildVazio(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shopping_cart_outlined, size: 56, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text('Seu carrinho está vazio', style: AppTextStyles.tituloSecao(size: 18)),
            const SizedBox(height: 6),
            Text(
              'Adicione produtos do cardápio para continuar.',
              textAlign: TextAlign.center,
              style: AppTextStyles.subtituloLogin(size: 14),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 230,
              child: AppButton(
                label: 'VOLTAR AOS PRODUTOS',
                onPressed: () => AppNavigation.irParaAba(context, AppTab.produtos),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRodape(CartProvider cart) {
    final resumo = cart.resumo;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        decoration: const BoxDecoration(
          color: AppColors.background,
          border: Border(top: BorderSide(color: AppColors.cardBorder)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLinhaResumo('Subtotal', resumo.subtotal),
            const SizedBox(height: 6),
            _buildLinhaResumo('Taxa de entrega', resumo.taxaEntrega),
            FreeDeliveryHint(regra: cart.regraEntrega, subtotal: resumo.subtotal),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(height: 1, color: AppColors.cardBorder),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total', style: AppTextStyles.tituloSecao(size: 16)),
                Text(formatarPreco(resumo.total), style: AppTextStyles.precoProduto.copyWith(fontSize: 20)),
              ],
            ),
            const SizedBox(height: 16),
            AppButton(
              label: 'FINALIZAR PEDIDO',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CheckoutScreen()),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => AppNavigation.irParaAba(context, AppTab.produtos),
              child: Text('Voltar aos Produtos', style: AppTextStyles.linkSenha(size: 14)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinhaResumo(String label, double valor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.subtituloLogin(size: 14).copyWith(color: AppColors.textLabel)),
        Text(
          formatarPreco(valor),
          style: AppTextStyles.subtituloLogin(size: 14).copyWith(
            color: AppColors.textDark,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _CartItemTile extends StatelessWidget {
  const _CartItemTile({required this.item, required this.cart});

  final CartItem item;
  final CartProvider cart;

  /// Remove o item (chamado tanto pelo botão de lixeira quanto pelo
  /// swipe) e oferece "Desfazer" na SnackBar como feedback/confirmação.
  void _remover(BuildContext context) {
    final produto = item.product;
    final quantidadeRemovida = item.quantity;
    cart.removeProduct(produto.id);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${produto.name} removido do carrinho'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.textDark,
          action: SnackBarAction(
            label: 'DESFAZER',
            textColor: Colors.white,
            onPressed: () => cart.addProduct(produto, quantity: quantidadeRemovida),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(item.product.id),
      direction: DismissDirection.endToStart,
      background: _buildFundoRemover(),
      onDismissed: (_) => _remover(context),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(width: 64, height: 64, child: ProductImage(path: item.product.imageUrl)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    style: AppTextStyles.nomeProduto,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text('${formatarPreco(item.product.price)} / un', style: AppTextStyles.descricaoProduto),
                  const SizedBox(height: 8),
                  QuantityStepper(
                    compact: true,
                    quantity: item.quantity,
                    processando: cart.isProcessing(item.product.id),
                    // Quantidade mínima é 1: abaixo disso, quem remove o
                    // item é o botão de lixeira, não o "-".
                    onDecrement: item.quantity > 1
                        ? () => cart.updateQuantity(item.product.id, item.quantity - 1)
                        : null,
                    // Trava no estoque: não deixa passar do que existe.
                    onIncrement: cart.atingiuLimite(item.product)
                        ? null
                        : () => cart.updateQuantity(item.product.id, item.quantity + 1),
                    avisoLimite: CartProvider.mensagemLimiteEstoque,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  tooltip: 'Remover',
                  onPressed: () => _remover(context),
                  icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.errorText),
                ),
                const SizedBox(height: 18),
                Text(formatarPreco(item.subtotal), style: AppTextStyles.precoProduto.copyWith(fontSize: 14)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFundoRemover() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 24),
      decoration: BoxDecoration(color: AppColors.errorText, borderRadius: BorderRadius.circular(14)),
      child: const Icon(Icons.delete_outline, color: Colors.white),
    );
  }
}
