import 'package:flutter/material.dart';

import '../core/app_assets.dart';

/// Imagem de um produto, pronta para os dois cenários que o app vai
/// enfrentar: hoje, um asset local de placeholder para todos os itens;
/// amanhã, uma URL real vinda da API. Decide sozinha qual carregar a
/// partir do valor de [path] e cai de volta no placeholder se a URL de
/// rede falhar (imagem quebrada, sem internet etc.), sem precisar de
/// nenhuma mudança nas telas quando as fotos reais chegarem.
class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    required this.path,
    this.fit = BoxFit.cover,
  });

  final String path;
  final BoxFit fit;

  bool get _isNetworkUrl => path.startsWith('http://') || path.startsWith('https://');

  @override
  Widget build(BuildContext context) {
    if (_isNetworkUrl) {
      return Image.network(
        path,
        fit: fit,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const _ImagemCarregando();
        },
        errorBuilder: (context, error, stackTrace) => Image.asset(
          AppAssets.placeholderProduto,
          fit: fit,
        ),
      );
    }

    return Image.asset(path, fit: fit);
  }
}

class _ImagemCarregando extends StatelessWidget {
  const _ImagemCarregando();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFF3F4F6),
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}
