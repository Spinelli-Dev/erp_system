import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_assets.dart';
import '../core/app_colors.dart';
import '../core/app_text_styles.dart';
import '../models/product.dart';
import '../providers/product_provider.dart';
import '../widgets/category_chip.dart';
import '../widgets/product_card.dart';
import '../widgets/product_card_skeleton.dart';
import 'product_detail_screen.dart';

/// Aba "Produtos" (ver `MainShell`): cardápio de produtos com filtro por categoria.
///
/// Hierarquia: AppBar (marca + carrinho) -> barra de categorias em scroll
/// horizontal -> grid de 2 colunas com os cards de produto. Todo o estado
/// (lista, categoria selecionada, loading/erro) vem do [ProductProvider];
/// esta tela só decide o que renderizar a partir dele.
class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: _buildAppBar(context),
      body: Consumer<ProductProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              _buildBarraCategorias(provider),
              Expanded(child: _buildConteudo(context, provider)),
            ],
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    // Sem ícone de carrinho aqui: o atalho (com o badge de quantidade)
    // fica na aba Carrinho da barra inferior.
    return AppBar(
      backgroundColor: AppColors.primary,
      elevation: 0,
      centerTitle: false,
      automaticallyImplyLeading: false,
      titleSpacing: 16,
      title: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.asset(AppAssets.logo, width: 32, height: 32, fit: BoxFit.cover),
          ),
          const SizedBox(width: 10),
          Text('Maxi Massas', style: AppTextStyles.appBarTitulo),
        ],
      ),
    );
  }

  Widget _buildBarraCategorias(ProductProvider provider) {
    if (provider.status == ProductLoadStatus.error) return const SizedBox.shrink();

    final categorias = provider.categories;
    if (categorias.isEmpty) return const SizedBox(height: 8);

    return Container(
      height: 58,
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: categorias.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final categoria = categorias[index];
          return CategoryChip(
            label: categoria,
            selected: categoria == provider.selectedCategory,
            onTap: () => provider.selectCategory(categoria),
          );
        },
      ),
    );
  }

  Widget _buildConteudo(BuildContext context, ProductProvider provider) {
    switch (provider.status) {
      case ProductLoadStatus.loading:
        return _buildGridSkeleton();
      case ProductLoadStatus.error:
        return _buildErro(provider);
      case ProductLoadStatus.loaded:
        final produtos = provider.filteredProducts;
        if (produtos.isEmpty) return _buildVazio();
        return _buildGrid(context, produtos);
    }
  }

  Widget _buildGrid(BuildContext context, List<Product> produtos) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: produtos.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.62,
      ),
      itemBuilder: (context, index) {
        final produto = produtos[index];
        return ProductCard(
          product: produto,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ProductDetailScreen(product: produto)),
          ),
        );
      },
    );
  }

  Widget _buildGridSkeleton() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: 6,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.62,
      ),
      itemBuilder: (_, __) => const ProductCardSkeleton(),
    );
  }

  Widget _buildErro(ProductProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 56, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(
              provider.errorMessage ?? 'Não foi possível carregar o cardápio.',
              textAlign: TextAlign.center,
              style: AppTextStyles.subtituloLogin(size: 14),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: provider.loadProducts,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVazio() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.ramen_dining_outlined, size: 56, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(
              'Nenhum produto encontrado nesta categoria.',
              textAlign: TextAlign.center,
              style: AppTextStyles.subtituloLogin(size: 14),
            ),
          ],
        ),
      ),
    );
  }
}
