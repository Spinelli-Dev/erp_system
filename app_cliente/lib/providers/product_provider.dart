import 'package:flutter/foundation.dart';

import '../models/product.dart';
import '../services/product_service.dart';

enum ProductLoadStatus { loading, loaded, error }

/// Estado da listagem de produtos: carregamento, erro, lista completa e
/// filtro de categoria selecionado. A tela de produtos só observa este
/// provider — quem decide "o que mostrar" é ele, não o widget.
class ProductProvider extends ChangeNotifier {
  ProductProvider({ProductService? service}) : _service = service ?? MockProductService() {
    loadProducts();
  }

  final ProductService _service;

  ProductLoadStatus _status = ProductLoadStatus.loading;
  List<Product> _products = const [];
  String? _errorMessage;
  String _selectedCategory = ProductCategories.todas;
  Future<void>? _carregamento;

  ProductLoadStatus get status => _status;
  String? get errorMessage => _errorMessage;
  String get selectedCategory => _selectedCategory;
  List<Product> get products => _products;

  /// Categorias existentes nos produtos carregados, com "Todas" sempre
  /// na frente. Deriva da lista em vez de ficar fixa para acompanhar o
  /// cardápio real assim que vier da API.
  List<String> get categories {
    final encontradas = _products.map((p) => p.category).toSet().toList()..sort();
    return [ProductCategories.todas, ...encontradas];
  }

  List<Product> get filteredProducts {
    if (_selectedCategory == ProductCategories.todas) return _products;
    return _products.where((p) => p.category == _selectedCategory).toList();
  }

  Future<void> loadProducts() => _carregamento = _carregar();

  /// Garante o cardápio carregado antes de usá-lo fora da aba de produtos
  /// (ex.: "Repetir pedido" aberto direto em Meus Pedidos): espera a carga
  /// em andamento, ou tenta de novo se a última falhou.
  Future<void> garantirCarregado() async {
    if (_status == ProductLoadStatus.loaded) return;
    if (_status == ProductLoadStatus.loading && _carregamento != null) {
      await _carregamento;
      if (_status == ProductLoadStatus.loaded) return;
    }
    await loadProducts();
  }

  Future<void> _carregar() async {
    _status = ProductLoadStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _products = await _service.fetchProducts();
      _status = ProductLoadStatus.loaded;
    } catch (_) {
      _status = ProductLoadStatus.error;
      _errorMessage = 'Não foi possível carregar o cardápio. Verifique sua conexão e tente novamente.';
    }
    notifyListeners();
  }

  void selectCategory(String category) {
    if (category == _selectedCategory) return;
    _selectedCategory = category;
    notifyListeners();
  }
}
