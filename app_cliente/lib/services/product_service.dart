import '../models/product.dart';
import 'api_client.dart';

/// Categorias fixas do cardápio. Centralizadas aqui para reaproveitar em
/// filtros e nos dados mockados, evitando strings soltas pelo código.
class ProductCategories {
  ProductCategories._();

  static const todas = 'Todas';
  static const massas = 'Massas';
  static const molhos = 'Molhos';
  static const lasanhas = 'Lasanhas';
  static const bebidas = 'Bebidas';
  static const sobremesas = 'Sobremesas';
}

/// Contrato de acesso a dados de produtos: [ApiProductService] busca o
/// cardápio no backend; [MockProductService] usa dados fixos quando o app
/// roda sem API configurada (ver `main.dart`). Como as telas dependem apenas desta interface
/// (injetada no `ProductProvider`), a troca não exige nenhuma mudança de UI.
abstract class ProductService {
  Future<List<Product>> fetchProducts();
}

/// Cardápio vindo de `GET /api/app/produtos` (público, sem login). Os IDs
/// são os do banco — é com eles que o pedido é enviado.
class ApiProductService implements ProductService {
  ApiProductService(this._api);

  final ApiClient _api;

  @override
  Future<List<Product>> fetchProducts() async {
    final data = await _api.get('/app/produtos') as List<dynamic>;
    return [
      for (final json in data.cast<Map<String, dynamic>>())
        Product(
          id: json['id'].toString(),
          name: json['nome'] as String? ?? '',
          description: json['descricao'] as String? ?? '',
          price: (json['preco'] as num?)?.toDouble() ?? 0,
          category: json['categoria'] as String? ?? 'Outros',
          isAvailable: json['disponivel'] as bool? ?? true,
          stock: json['estoque'] as int?,
        ),
    ];
  }
}

/// Implementação mockada, usada quando o app roda sem API configurada.
/// Simula a latência de uma chamada de rede.
class MockProductService implements ProductService {
  @override
  Future<List<Product>> fetchProducts() async {
    await Future.delayed(const Duration(milliseconds: 900));
    return _mockProducts;
  }
}

final List<Product> _mockProducts = [
  const Product(
    id: '1',
    name: 'Espaguete Tradicional',
    description: 'Massa fresca artesanal, feita no dia, ideal para acompanhar qualquer molho.',
    price: 24.90,
    category: ProductCategories.massas,
    ingredients: ['Farinha de trigo', 'Ovos', 'Sêmola'],
  ),
  const Product(
    id: '2',
    name: 'Talharim ao Ovo',
    description: 'Talharim artesanal com massa mais espessa e sabor marcante.',
    price: 26.90,
    category: ProductCategories.massas,
    ingredients: ['Farinha de trigo', 'Ovos'],
  ),
  const Product(
    id: '3',
    name: 'Ravioli de Ricota',
    description: 'Recheado com ricota fresca e temperos da casa.',
    price: 32.90,
    category: ProductCategories.massas,
    ingredients: ['Massa fresca', 'Ricota', 'Salsinha', 'Noz-moscada'],
  ),
  const Product(
    id: '4',
    name: 'Molho Bolonhesa',
    description: 'Molho de carne moída, cozido lentamente com tomate e ervas.',
    price: 18.90,
    category: ProductCategories.molhos,
    ingredients: ['Carne moída', 'Tomate', 'Cebola', 'Alho', 'Orégano'],
  ),
  const Product(
    id: '5',
    name: 'Molho Sugo',
    description: 'Molho de tomate tradicional, leve e encorpado.',
    price: 14.90,
    category: ProductCategories.molhos,
    ingredients: ['Tomate', 'Manjericão', 'Alho', 'Azeite'],
  ),
  const Product(
    id: '6',
    name: 'Molho Branco',
    description: 'Molho cremoso à base de leite, amanteigado e suave.',
    price: 16.90,
    category: ProductCategories.molhos,
    ingredients: ['Leite', 'Manteiga', 'Farinha', 'Noz-moscada'],
  ),
  const Product(
    id: '7',
    name: 'Lasanha à Bolonhesa',
    description: 'Camadas de massa fresca, molho bolonhesa e queijo gratinado.',
    price: 38.90,
    category: ProductCategories.lasanhas,
    ingredients: ['Massa fresca', 'Carne moída', 'Molho de tomate', 'Queijo'],
  ),
  const Product(
    id: '8',
    name: 'Lasanha Quatro Queijos',
    description: 'Combinação de queijos selecionados em camadas generosas.',
    price: 41.90,
    category: ProductCategories.lasanhas,
    ingredients: ['Massa fresca', 'Mussarela', 'Parmesão', 'Provolone', 'Gorgonzola'],
    isAvailable: false,
  ),
  const Product(
    id: '9',
    name: 'Suco Natural',
    description: 'Suco de fruta natural, feito na hora, sem conservantes.',
    price: 9.90,
    category: ProductCategories.bebidas,
    ingredients: ['Fruta da estação', 'Água'],
  ),
  const Product(
    id: '10',
    name: 'Refrigerante Lata',
    description: 'Lata gelada, ótima companhia para o prato principal.',
    price: 6.50,
    category: ProductCategories.bebidas,
  ),
  const Product(
    id: '11',
    name: 'Tiramisù',
    description: 'Clássica sobremesa italiana com café e mascarpone.',
    price: 19.90,
    category: ProductCategories.sobremesas,
    ingredients: ['Mascarpone', 'Café', 'Biscoito champanhe', 'Cacau'],
  ),
  const Product(
    id: '12',
    name: 'Panna Cotta',
    description: 'Sobremesa cremosa com calda de frutas vermelhas.',
    price: 17.90,
    category: ProductCategories.sobremesas,
    ingredients: ['Creme de leite', 'Baunilha', 'Frutas vermelhas'],
  ),
];
