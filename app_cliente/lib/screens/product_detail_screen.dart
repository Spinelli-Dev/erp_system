import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../core/app_text_styles.dart';
import '../core/formatters.dart';
import '../models/product.dart';
import '../navigation/app_navigation.dart';
import '../providers/cart_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/product_provider.dart';
import '../widgets/app_button.dart';
import '../widgets/product_image.dart';
import '../widgets/quantity_stepper.dart';

/// Tela de detalhes de um produto: foto grande, descrição completa,
/// ingredientes, seletor de quantidade e botão de adicionar ao carrinho.
class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.product});

  final Product product;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantidade = 1;

  void _alterarQuantidade(int delta) {
    final nova = _quantidade + delta;
    if (nova < 1 || nova > _restante) return;
    setState(() => _quantidade = nova);
  }

  /// O produto com estoque e preço atuais: o cardápio é buscado de novo em
  /// segundo plano (ver `atualizarCardapioECarrinho`), então o que veio ao
  /// abrir a tela pode estar velho. Sem o cardápio no app (ex.: testes da
  /// tela isolada), usa o produto recebido.
  Product _atual({bool ouvir = false}) {
    try {
      final cardapio = ouvir ? context.watch<ProductProvider>() : context.read<ProductProvider>();
      return cardapio.produtoAtual(widget.product.id) ?? widget.product;
    } on ProviderNotFoundException {
      return widget.product;
    }
  }

  /// Quanto ainda cabe no carrinho: o estoque menos o que já está nele.
  int get _restante => context.read<CartProvider>().restanteEmEstoque(_atual());

  void _adicionarAoCarrinho() {
    final product = _atual();
    final adicionadas = context.read<CartProvider>().addProduct(product, quantity: _quantidade);
    if (adicionadas == 0) return;
    HapticFeedback.lightImpact();

    // Capturada agora: quando o usuário tocar em "VER CARRINHO", esta
    // tela já terá sido fechada e o `context` não serve mais.
    final irParaCarrinho = AppNavigation.acaoIrParaAba(context, AppTab.carrinho);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            '$adicionadas ${adicionadas == 1 ? 'unidade' : 'unidades'} de ${product.name} adicionada${adicionadas == 1 ? '' : 's'} ao carrinho',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.textDark,
          action: SnackBarAction(
            label: 'VER CARRINHO',
            textColor: Colors.white,
            onPressed: irParaCarrinho,
          ),
        ),
      );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final product = _atual(ouvir: true);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.primary,
            expandedHeight: 260,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'produto-${product.id}',
                child: ProductImage(path: product.imageUrl),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(product.name, style: AppTextStyles.tituloSecao(size: 22)),
                      ),
                      const SizedBox(width: 12),
                      Text(formatarPreco(product.price), style: AppTextStyles.precoProduto.copyWith(fontSize: 19)),
                    ],
                  ),
                  if (!product.isAvailable) ...[
                    const SizedBox(height: 10),
                    _buildAvisoIndisponivel(),
                  ],
                  const SizedBox(height: 16),
                  Text('Descrição', style: AppTextStyles.label(size: 13)),
                  const SizedBox(height: 6),
                  Text(
                    product.description,
                    style: AppTextStyles.subtituloLogin(size: 14).copyWith(color: AppColors.textDark, height: 1.5),
                  ),
                  if (product.ingredients.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text('Ingredientes', style: AppTextStyles.label(size: 13)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: product.ingredients
                          .map((ingrediente) => _buildIngredienteChip(ingrediente))
                          .toList(),
                    ),
                  ],
                  // Espaço reservado para a barra fixa de quantidade + botão.
                  const SizedBox(height: 110),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: product.isAvailable ? _buildBarraInferior() : null,
    );
  }

  Widget _buildAvisoIndisponivel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.errorBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.errorBorder),
      ),
      child: Text('Produto indisponível no momento', style: AppTextStyles.erro),
    );
  }

  Widget _buildIngredienteChip(String ingrediente) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Text(ingrediente, style: AppTextStyles.chip(selecionado: false)),
    );
  }

  Widget _buildBarraInferior() {
    // Reconstrói se o carrinho mudar (o que já está nele conta no limite).
    final restante = context.watch<CartProvider>().restanteEmEstoque(_atual());
    final esgotadoNoCarrinho = restante == 0;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Row(
          children: [
            QuantityStepper(
              quantity: _quantidade,
              onIncrement: _quantidade < restante ? () => _alterarQuantidade(1) : null,
              onDecrement: _quantidade > 1 ? () => _alterarQuantidade(-1) : null,
              avisoLimite: CartProvider.mensagemLimiteEstoque,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: AppButton(
                label: esgotadoNoCarrinho
                    ? 'ESTOQUE JÁ NO CARRINHO'
                    : 'ADICIONAR • ${formatarPreco(_atual().price * _quantidade)}',
                onPressed: esgotadoNoCarrinho ? null : _adicionarAoCarrinho,
              ),
            ),
          ],
        ),
      ),
    );
  }

}
