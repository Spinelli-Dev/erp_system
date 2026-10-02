/// Caminhos de assets centralizados, para não espalhar strings de path
/// pelo código e facilitar a troca quando os assets reais chegarem.
class AppAssets {
  AppAssets._();

  static const logo = 'assets/images/logo.png';

  /// Placeholder usado em todos os produtos até que as fotos reais de
  /// cada item cheguem. Quando isso acontecer, basta o backend passar a
  /// enviar a URL real em [Product.imageUrl] — o widget [ProductImage]
  /// já sabe diferenciar um asset local de uma URL de rede e cai de
  /// volta neste placeholder em caso de erro.
  static const placeholderProduto = 'assets/images/imagem_temporario.png';
}
