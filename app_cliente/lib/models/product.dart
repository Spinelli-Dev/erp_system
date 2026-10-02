import '../core/app_assets.dart';

/// Modelo de um produto do cardápio (massa, molho, bebida, sobremesa...).
///
/// Inclui [fromJson]/[toJson] para já nascer pronto para a integração com
/// a API real: quando o backend estiver disponível, basta implementar um
/// [ProductService] que faça a chamada HTTP e mapeie a resposta com
/// `Product.fromJson`, sem precisar tocar nas telas.
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    this.imageUrl = AppAssets.placeholderProduto,
    this.ingredients = const [],
    this.isAvailable = true,
    this.stock,
  });

  final String id;
  final String name;
  final String description;
  final double price;

  /// Caminho de um asset local (ex.: `assets/images/...`) ou, quando a
  /// API já fornecer fotos reais, uma URL `http(s)://...`.
  final String imageUrl;

  final String category;
  final List<String> ingredients;
  final bool isAvailable;

  /// Unidades em estoque — o máximo que o cliente consegue colocar no
  /// carrinho. `null` = sem limite conhecido (cardápio mockado).
  final int? stock;

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'].toString(),
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      imageUrl: (json['imageUrl'] as String?)?.trim().isNotEmpty == true
          ? json['imageUrl'] as String
          : AppAssets.placeholderProduto,
      category: json['category'] as String? ?? 'Outros',
      ingredients: (json['ingredients'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      isAvailable: json['isAvailable'] as bool? ?? true,
      stock: json['stock'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'price': price,
        'imageUrl': imageUrl,
        'category': category,
        'ingredients': ingredients,
        'isAvailable': isAvailable,
        'stock': stock,
      };
}
