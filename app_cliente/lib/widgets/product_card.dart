import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../core/app_text_styles.dart';
import '../core/formatters.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import 'product_image.dart';

/// Card de produto do grid. Mostra imagem, nome, descrição breve, preço
/// destacado e um botão de adicionar com feedback visual (o "+" vira um
/// check por um instante; o contador do carrinho na barra inferior também
/// é atualizado).
class ProductCard extends StatefulWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
  });

  final Product product;
  final VoidCallback onTap;

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _acabouDeAdicionar = false;

  void _adicionarAoCarrinho() {
    final product = widget.product;
    if (!product.isAvailable) return;

    if (context.read<CartProvider>().addProduct(product) == 0) return;
    HapticFeedback.lightImpact();

    setState(() => _acabouDeAdicionar = true);
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _acabouDeAdicionar = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return Material(
      color: AppColors.cardBackground,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      child: InkWell(
        onTap: widget.onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.cardBorder),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImagem(product),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: AppTextStyles.nomeProduto,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      product.description,
                      style: AppTextStyles.descricaoProduto,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            formatarPreco(product.price),
                            style: AppTextStyles.precoProduto,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _buildBotaoAdicionar(product),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagem(Product product) {
    return AspectRatio(
      aspectRatio: 1.1,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Hero(
            tag: 'produto-${product.id}',
            child: ProductImage(path: product.imageUrl),
          ),
          if (!product.isAvailable)
            Container(
              color: Colors.black.withValues(alpha: 0.45),
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Indisponível',
                  style: AppTextStyles.chip(selecionado: false).copyWith(fontSize: 11),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBotaoAdicionar(Product product) {
    // Trava também quando o carrinho já tem todo o estoque do produto.
    final noLimite = product.isAvailable && context.watch<CartProvider>().atingiuLimite(product);
    final disponivel = product.isAvailable && !noLimite;

    final botao = SizedBox(
      width: 34,
      height: 34,
      child: Material(
        color: disponivel
            ? (_acabouDeAdicionar ? AppColors.success : AppColors.primary)
            : AppColors.textMuted.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: disponivel ? _adicionarAoCarrinho : null,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              _acabouDeAdicionar ? Icons.check : Icons.add,
              key: ValueKey(_acabouDeAdicionar),
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ),
    );

    if (!noLimite) return botao;
    // Tocar no botão travado explica o motivo, em vez de não fazer nada.
    return Tooltip(
      message: CartProvider.mensagemLimiteEstoque,
      triggerMode: TooltipTriggerMode.tap,
      showDuration: const Duration(seconds: 2),
      child: botao,
    );
  }
}
