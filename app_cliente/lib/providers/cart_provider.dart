import 'package:flutter/foundation.dart';

import '../models/cart_item.dart';
import '../models/cart_total.dart';
import '../models/delivery_fee_rule.dart';
import '../models/product.dart';
import '../services/delivery_fee_service.dart';

/// Estado do carrinho de compras, compartilhado pelo app via Provider.
///
/// Mantém os itens por `productId` para permitir somar quantidades ao
/// adicionar o mesmo produto mais de uma vez, e notifica os widgets
/// interessados (badge do carrinho, tela de carrinho etc.) a cada mudança.
class CartProvider extends ChangeNotifier {
  /// [deliveryFeeService] busca a regra da taxa definida pelos gestores;
  /// sem ele (modo mock), vale [DeliveryFeeRule.padrao].
  CartProvider({DeliveryFeeService? deliveryFeeService}) : _deliveryFeeService = deliveryFeeService {
    atualizarRegraEntrega();
  }

  final DeliveryFeeService? _deliveryFeeService;
  DeliveryFeeRule _regraEntrega = DeliveryFeeRule.padrao;
  bool _descartado = false;

  /// Regra da taxa de entrega em vigor. A tela de finalização também a
  /// usa — lá a taxa só entra se o cliente escolher receber no endereço.
  DeliveryFeeRule get regraEntrega => _regraEntrega;

  /// Busca a regra de novo (chamado ao criar o provider e ao abrir a
  /// finalização do pedido). Se falhar, mantém a última conhecida — o
  /// servidor recalcula a taxa no pedido de qualquer forma.
  Future<void> atualizarRegraEntrega() async {
    final servico = _deliveryFeeService;
    if (servico == null) return;
    try {
      final regra = await servico.buscarRegra();
      if (_descartado) return;
      _regraEntrega = regra;
      notifyListeners();
    } catch (_) {}
  }

  @override
  void dispose() {
    _descartado = true;
    super.dispose();
  }

  final Map<String, CartItem> _items = {};

  /// Ids de produtos com uma alteração de quantidade em andamento — usado
  /// para mostrar o spinner no lugar do seletor +/- daquele item enquanto
  /// a mudança é "sincronizada" (ver [updateQuantity]).
  final Set<String> _idsProcessando = {};

  List<CartItem> get items => List.unmodifiable(_items.values);

  bool get isEmpty => _items.isEmpty;

  /// Soma das quantidades de todos os itens — usado no badge do carrinho.
  int get totalItems => _items.values.fold(0, (soma, item) => soma + item.quantity);

  double get totalPrice => _items.values.fold(0.0, (soma, item) => soma + item.subtotal);

  /// Taxa de entrega para o carrinho atual (zero se vazio ou se chegou ao
  /// pedido mínimo para entrega grátis).
  double get taxaEntrega => isEmpty ? 0 : _regraEntrega.taxaPara(totalPrice);

  /// Resumo pronto para o rodapé da tela de carrinho (subtotal + taxa +
  /// total).
  CartTotal get resumo => CartTotal(subtotal: totalPrice, taxaEntrega: taxaEntrega);

  int quantityOf(String productId) => _items[productId]?.quantity ?? 0;

  bool isProcessing(String productId) => _idsProcessando.contains(productId);

  /// Mensagem do aviso mostrado quando o "+" trava no limite do estoque.
  static const mensagemLimiteEstoque = 'Limite máximo em estoque atingido';

  /// Quantas unidades de [product] ainda cabem no carrinho: o estoque menos
  /// o que já está nele. Sem estoque conhecido ([Product.stock] nulo), não
  /// há limite. O servidor confere o estoque de novo no pedido.
  int restanteEmEstoque(Product product) {
    final estoque = product.stock;
    if (estoque == null) return 1 << 30;
    return (estoque - quantityOf(product.id)).clamp(0, estoque);
  }

  /// O carrinho já tem todo o estoque deste produto (o "+" deve travar).
  bool atingiuLimite(Product product) => restanteEmEstoque(product) == 0;

  /// Adiciona até o limite do estoque e devolve quantas unidades entraram
  /// de fato (0 se o carrinho já tinha tudo o que há em estoque).
  int addProduct(Product product, {int quantity = 1}) {
    final adicionar = quantity.clamp(0, restanteEmEstoque(product));
    if (adicionar == 0) return 0;

    final existente = _items[product.id];
    if (existente != null) {
      existente.quantity += adicionar;
    } else {
      _items[product.id] = CartItem(product: product, quantity: adicionar);
    }
    notifyListeners();
    return adicionar;
  }

  void removeProduct(String productId) {
    _items.remove(productId);
    _idsProcessando.remove(productId);
    notifyListeners();
  }

  /// Atualiza a quantidade de um item. A quantidade mínima é 1 — chamadas
  /// com valor menor são ignoradas (não removem o item). Para tirar um
  /// produto do carrinho, use [removeProduct] (o botão de lixeira): assim
  /// o usuário não perde o item sem querer só por tocar demais no "-".
  ///
  /// Simula uma breve sincronização (ex.: revalidar estoque disponível na
  /// API) para dar tempo do estado de loading aparecer no seletor —
  /// quando a integração real existir, é só trocar o `Future.delayed`
  /// pela chamada HTTP correspondente.
  Future<void> updateQuantity(String productId, int quantity) async {
    if (quantity < 1) return;
    final item = _items[productId];
    if (item == null) return;
    // Acima do estoque também é ignorado: o "+" já fica travado no limite.
    final estoque = item.product.stock;
    if (estoque != null && quantity > estoque) return;

    _idsProcessando.add(productId);
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 350));

    // O item pode ter sido removido enquanto a "sincronização" corria.
    if (_items.containsKey(productId)) {
      item.quantity = quantity;
    }
    _idsProcessando.remove(productId);
    notifyListeners();
  }

  /// Coloca de novo no carrinho os itens de um pedido anterior, com as
  /// mesmas quantidades. Usa o produto como está hoje no [catalogo] (preço
  /// e estoque atuais), pula o que saiu do cardápio ou está indisponível e
  /// limita cada item ao que há em estoque.
  RepeticaoPedido repetirItens(List<CartItem> itensDoPedido, List<Product> catalogo) {
    final porId = {for (final produto in catalogo) produto.id: produto};
    var unidadesAdicionadas = 0;
    final indisponiveis = <String>[];

    for (final item in itensDoPedido) {
      final atual = porId[item.product.id];
      final cabem = atual == null || !atual.isAvailable ? 0 : item.quantity.clamp(0, restanteEmEstoque(atual));
      if (cabem == 0) {
        indisponiveis.add(item.product.name);
        continue;
      }
      if (cabem < item.quantity) {
        indisponiveis.add('${item.product.name} (só $cabem de ${item.quantity}: limite do estoque)');
      }
      final existente = _items[atual!.id];
      if (existente != null) {
        existente.quantity += cabem;
      } else {
        _items[atual.id] = CartItem(product: atual, quantity: cabem);
      }
      unidadesAdicionadas += cabem;
    }

    // Uma notificação só, no fim: o badge pula direto para o total.
    if (unidadesAdicionadas > 0) notifyListeners();
    return RepeticaoPedido(unidadesAdicionadas: unidadesAdicionadas, indisponiveis: indisponiveis);
  }

  void clear() {
    _items.clear();
    _idsProcessando.clear();
    notifyListeners();
  }
}

/// Resultado de [CartProvider.repetirItens].
class RepeticaoPedido {
  const RepeticaoPedido({required this.unidadesAdicionadas, required this.indisponiveis});

  /// Soma das quantidades que entraram no carrinho.
  final int unidadesAdicionadas;

  /// Produtos do pedido que não puderam ser adicionados, ou que entraram
  /// só em parte por causa do estoque (com a quantidade no texto).
  final List<String> indisponiveis;

  bool get nadaAdicionado => unidadesAdicionadas == 0;
}
