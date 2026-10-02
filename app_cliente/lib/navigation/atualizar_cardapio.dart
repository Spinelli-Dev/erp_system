import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../providers/cart_provider.dart';
import '../providers/product_provider.dart';

/// Busca o cardápio de novo e ajusta o carrinho ao estoque atual.
///
/// O estoque muda fora do app (vendas no balcão, ajustes no painel, outros
/// clientes), então o app não pode confiar no que leu ao abrir. Chamado ao
/// voltar para o cardápio ou o carrinho, ao trazer o app de volta para a
/// frente, a cada minuto nessas abas e no "puxar para atualizar".
///
/// Se o carrinho tinha mais do que há em estoque, ele é reduzido e o cliente
/// vê um aviso dizendo o que mudou. O servidor confere o estoque de novo ao
/// receber o pedido, então isto é para o cliente não ser surpreendido lá.
Future<void> atualizarCardapioECarrinho(BuildContext context) async {
  final produtos = context.read<ProductProvider>();
  final carrinho = context.read<CartProvider>();
  final avisos = ScaffoldMessenger.maybeOf(context);

  if (!await produtos.atualizar()) return;
  final ajustes = carrinho.sincronizarComCardapio(produtos.products);
  if (ajustes.isEmpty || avisos == null) return;

  avisos
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text('Carrinho atualizado com o estoque atual:\n${ajustes.join('\n')}'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textDark,
        duration: const Duration(seconds: 6),
      ),
    );
}
