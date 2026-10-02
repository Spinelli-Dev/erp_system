import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../core/app_text_styles.dart';
import '../core/formatters.dart';
import '../core/payment_instructions.dart';
import '../models/address.dart';
import '../models/delivery_type.dart';
import '../models/franchise_info.dart';
import '../models/order_confirmation.dart';
import '../models/order_request.dart';
import '../models/payment_method.dart';
import '../models/user_profile.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/order_history_provider.dart';
import '../providers/product_provider.dart';
import '../services/franchise_service.dart';
import '../services/order_service.dart';
import '../widgets/app_button.dart';
import '../widgets/address_fields.dart';
import '../widgets/app_text_field.dart';
import '../widgets/category_chip.dart';
import '../widgets/payment_method_card.dart';
import '../widgets/free_delivery_hint.dart';
import '../widgets/segmented_toggle.dart';
import 'order_confirmation_screen.dart';

/// Tela de finalização do pedido: tipo de entrega, endereço (ou retirada
/// no local), forma de pagamento, observações e o resumo com o total —
/// aberta a partir do botão "Finalizar Pedido" da tela de carrinho.
///
/// Reaproveita as mesmas cores/tipografia/componentes das telas de
/// produtos e carrinho ([AppColors], [AppTextStyles], [AppButton],
/// [AppTextField], [CategoryChip]) e lê o mesmo [CartProvider] para o
/// resumo do pedido.
///
/// Contato e endereços vêm do [AuthProvider] (os mesmos da aba Perfil):
/// o endereço principal já chega preenchido, os outros salvos podem ser
/// escolhidos em "Endereços salvos", e marcar "Salvar este endereço"
/// grava o endereço digitado no perfil quando o pedido é confirmado.
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({
    super.key,
    this.orderService,
    this.franchise = franquiaPadrao,
  });

  final OrderService? orderService;
  final FranchiseInfo franchise;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  // Ordem: o injetado no construtor (testes), o registrado no main.dart
  // (API real, quando configurada) e, sem nenhum dos dois, o mock.
  late final OrderService _orderService =
      widget.orderService ?? context.read<OrderService?>() ?? MockOrderService();

  final _formKeyEndereco = GlobalKey<FormState>();
  final _endereco = AddressFieldsController();
  final _observacoesController = TextEditingController();

  static const _horariosRetirada = ['Assim que possível', '19:00', '19:30', '20:00', '20:30'];

  DeliveryType _tipoEntrega = DeliveryType.delivery;
  PaymentMethod? _formaPagamento;
  bool _salvarEndereco = false;
  String _horarioRetirada = _horariosRetirada.first;
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    // Mesma proteção da tela de carrinho: o ScaffoldMessenger é único
    // para o app inteiro, então uma SnackBar de "produto adicionado" (ou
    // sua fila, se o usuário adicionou vários produtos rápido) pode
    // continuar aparecendo por cima desta tela também.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      // Os gestores podem ter mudado a taxa desde que o app abriu.
      context.read<CartProvider>().atualizarRegraEntrega();
    });
    // Endereço principal do perfil já vem preenchido. Antes de registrar
    // os listeners abaixo, que chamariam setState dentro do initState.
    final principal = _perfil?.mainAddress;
    if (principal != null) _preencherEndereco(principal);
    // Reavalia se o botão "Confirmar Pedido" pode ficar ativo a cada
    // letra digitada nos campos obrigatórios do endereço (validação em
    // tempo real, não só ao tentar enviar).
    _endereco.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  UserProfile? get _perfil => context.read<AuthProvider>().usuario;

  @override
  void dispose() {
    _endereco.dispose();
    _observacoesController.dispose();
    super.dispose();
  }

  bool get _enderecoPreenchido => _endereco.completo;

  bool get _podeConfirmar {
    if (_formaPagamento == null) return false;
    if (_tipoEntrega == DeliveryType.delivery) return _enderecoPreenchido;
    return true;
  }

  void _preencherEndereco(Address endereco) => _endereco.preencher(endereco);

  /// Se o que está nos campos já é um dos endereços salvos — aí não faz
  /// sentido oferecer (nem executar) "salvar para próximas compras".
  bool get _enderecoJaSalvo => (_perfil?.addresses ?? const <Address>[]).any((e) =>
      e.street == _endereco.rua.text.trim() &&
      e.number == _endereco.numero.text.trim() &&
      e.complement == _endereco.complemento.text.trim() &&
      e.neighborhood == _endereco.bairro.text.trim() &&
      e.city == _endereco.cidade.text.trim());

  Future<void> _escolherEnderecoSalvo() async {
    final enderecos = _perfil?.addresses ?? const <Address>[];
    final escolhido = await showModalBottomSheet<Address>(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text('Endereços salvos', style: AppTextStyles.tituloSecao(size: 16)),
            ),
            for (final endereco in enderecos)
              ListTile(
                onTap: () => Navigator.of(context).pop(endereco),
                leading: Icon(
                  endereco.isMain ? Icons.star_rounded : Icons.location_on_outlined,
                  color: endereco.isMain ? AppColors.primary : AppColors.textMuted,
                ),
                title: Text(endereco.linhaPrincipal, style: AppTextStyles.nomeProduto),
                subtitle: Text(endereco.linhaSecundaria, style: AppTextStyles.subtituloLogin(size: 12.5)),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
    if (escolhido != null && mounted) setState(() => _preencherEndereco(escolhido));
  }

  double _taxaEntrega(CartProvider cart) => _tipoEntrega == DeliveryType.delivery ? cart.taxaEntrega : 0;

  Future<void> _confirmarPedido(CartProvider cart) async {
    if (_tipoEntrega == DeliveryType.delivery) {
      final enderecoValido = _formKeyEndereco.currentState?.validate() ?? false;
      if (!enderecoValido) return;
    }
    if (_formaPagamento == null) return;

    setState(() => _enviando = true);

    // Instantâneo dos dados do carrinho — capturado ANTES de limpar, já
    // que a tela de confirmação precisa deles mesmo depois do
    // `cart.clear()` (e `cart.items` deixaria de existir depois disso).
    final itensSnapshot = cart.items;
    final subtotal = cart.totalPrice;
    final taxa = _taxaEntrega(cart);
    final total = subtotal + taxa;
    final agora = DateTime.now();

    final enderecoEntrega =
        _tipoEntrega == DeliveryType.delivery ? _endereco.montar(saveForFuture: _salvarEndereco) : null;

    final pedido = OrderRequest(
      userId: _perfil?.id ?? 'convidado',
      items: itensSnapshot,
      total: total,
      deliveryType: _tipoEntrega,
      deliveryAddress: enderecoEntrega,
      paymentMethod: _formaPagamento!,
      specialObservations: _observacoesController.text.trim(),
      scheduledTime: _tipoEntrega == DeliveryType.pickup ? _horarioRetirada : null,
      orderDate: agora,
    );

    final resultado = await _orderService.enviarPedido(pedido);

    if (!mounted) return;
    setState(() => _enviando = false);

    if (resultado.success) {
      // Valores que o servidor cobrou de fato (preço ou taxa podem ter
      // mudado desde que a tela abriu); sem eles (mock), os calculados aqui.
      final taxaCobrada = resultado.deliveryFee ?? taxa;
      final totalCobrado = resultado.total ?? total;
      final confirmacao = OrderConfirmation(
        orderId: resultado.orderNumber ?? '—',
        orderDate: agora,
        deliveryType: _tipoEntrega,
        deliveryAddress: enderecoEntrega,
        pickupLocation: widget.franchise,
        items: itensSnapshot,
        paymentMethod: _formaPagamento!,
        subtotal: resultado.subtotal ?? subtotal,
        deliveryFee: taxaCobrada,
        total: totalCobrado,
        specialObservations: _observacoesController.text.trim(),
        estimatedTimeMinutes: _tipoEntrega == DeliveryType.delivery
            ? widget.franchise.tempoEntregaMinutos
            : widget.franchise.tempoPreparoMinutos,
        paymentInstructions: gerarInstrucoesPagamento(
          method: _formaPagamento!,
          total: totalCobrado,
          franquia: widget.franchise,
        ),
      );

      // "Salvar para próximas compras": grava no perfil em segundo plano —
      // uma falha aqui não deve atrapalhar um pedido que já foi aceito.
      if (enderecoEntrega != null && _salvarEndereco && !_enderecoJaSalvo) {
        context.read<AuthProvider>().salvarEndereco(_endereco.montar());
      }

      // Guarda no histórico antes de limpar o carrinho — a tela de
      // confirmação não depende mais do CartProvider depois disso.
      context.read<OrderHistoryProvider>().adicionar(confirmacao);
      cart.clear();
      // O pedido baixou o estoque no servidor: o cardápio passa a mostrar o novo saldo.
      context.read<ProductProvider>().atualizar();

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => OrderConfirmationScreen(pedido: confirmacao)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(resultado.errorMessage ?? 'Não foi possível enviar o pedido. Tente novamente.')),
      );
      // A recusa mais comum é estoque (alguém comprou antes): busca o saldo
      // atual e ajusta o carrinho, para a próxima tentativa já dar certo.
      final produtos = context.read<ProductProvider>();
      if (await produtos.atualizar() && mounted) {
        final ajustes = cart.sincronizarComCardapio(produtos.products);
        if (ajustes.isNotEmpty && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Carrinho atualizado com o estoque atual:\n${ajustes.join('\n')}'),
              duration: const Duration(seconds: 6),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Reconstrói se o perfil mudar (ex.: endereço salvo em segundo plano).
    context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('Finalizar Pedido', style: AppTextStyles.appBarTitulo),
      ),
      body: Consumer<CartProvider>(
        builder: (context, cart, _) {
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_perfil != null) _buildContato(_perfil!),
                      _buildTituloSecao('Tipo de entrega'),
                      const SizedBox(height: 12),
                      SegmentedToggle<DeliveryType>(
                        options: const [DeliveryType.delivery, DeliveryType.pickup],
                        labels: const ['Receber no Endereço', 'Retirar no Local'],
                        selected: _tipoEntrega,
                        onChanged: (tipo) => setState(() => _tipoEntrega = tipo),
                      ),
                      const SizedBox(height: 20),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                        alignment: Alignment.topCenter,
                        child:
                            _tipoEntrega == DeliveryType.delivery ? _buildFormularioEndereco() : _buildInfoRetirada(),
                      ),
                      const SizedBox(height: 28),
                      _buildTituloSecao('Forma de pagamento'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          for (final metodo in PaymentMethod.values) ...[
                            if (metodo != PaymentMethod.values.first) const SizedBox(width: 10),
                            Expanded(
                              child: PaymentMethodCard(
                                method: metodo,
                                selected: _formaPagamento == metodo,
                                onTap: () => setState(() => _formaPagamento = metodo),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 28),
                      _buildTituloSecao('Observações'),
                      const SizedBox(height: 12),
                      _buildCampoObservacoes(),
                    ],
                  ),
                ),
              ),
              _buildRodape(cart),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTituloSecao(String titulo) => Text(titulo, style: AppTextStyles.tituloSecao(size: 16));

  Widget _buildContato(UserProfile perfil) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          const Icon(Icons.person_outline, size: 18, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Pedido para ${perfil.name} • ${perfil.phone}',
              style: AppTextStyles.subtituloLogin(size: 12.5),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormularioEndereco() {
    final temEnderecoSalvo = _perfil?.addresses.isNotEmpty ?? false;
    return Form(
      key: _formKeyEndereco,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        key: const ValueKey('form-endereco'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (temEnderecoSalvo) ...[
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _escolherEnderecoSalvo,
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
                icon: const Icon(Icons.bookmark_outline, size: 16, color: AppColors.primary),
                label: Text('Endereços salvos', style: AppTextStyles.linkSenha(size: 13)),
              ),
            ),
            const SizedBox(height: 8),
          ],
          AddressFields(controller: _endereco),
          const SizedBox(height: 12),
          if (!_enderecoJaSalvo)
            InkWell(
              onTap: () => setState(() => _salvarEndereco = !_salvarEndereco),
              borderRadius: BorderRadius.circular(8),
              child: Row(
                children: [
                  Checkbox(
                    value: _salvarEndereco,
                    activeColor: AppColors.primary,
                    onChanged: (valor) => setState(() => _salvarEndereco = valor ?? false),
                  ),
                  Expanded(
                    child: Text(
                      'Salvar este endereço para próximas compras',
                      style: AppTextStyles.subtituloLogin(size: 13),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRetirada() {
    final franquia = widget.franchise;
    return Column(
      key: const ValueKey('info-retirada'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.inputBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.inputBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.storefront_outlined, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(child: Text(franquia.name, style: AppTextStyles.nomeProduto)),
                ],
              ),
              const SizedBox(height: 10),
              _buildLinhaInfo(Icons.location_on_outlined, franquia.address),
              const SizedBox(height: 6),
              _buildLinhaInfo(Icons.schedule_outlined, franquia.hours),
              const SizedBox(height: 6),
              _buildLinhaInfo(Icons.call_outlined, franquia.phoneNumber),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(Icons.timer_outlined, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Sua compra estará pronta em ${franquia.tempoPreparoMinutos} minutos',
                  style: AppTextStyles.subtituloLogin(size: 13).copyWith(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text('Horário de retirada', style: AppTextStyles.label()),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _horariosRetirada
              .map(
                (horario) => CategoryChip(
                  label: horario,
                  selected: horario == _horarioRetirada,
                  onTap: () => setState(() => _horarioRetirada = horario),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildLinhaInfo(IconData icon, String texto) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(texto, style: AppTextStyles.subtituloLogin(size: 13).copyWith(color: AppColors.textDark)),
        ),
      ],
    );
  }

  Widget _buildCampoObservacoes() {
    return TextField(
      controller: _observacoesController,
      maxLength: 140,
      maxLines: 3,
      style: AppTextStyles.input,
      decoration: InputDecoration(
        hintText: 'Ex.: deixar na portaria, tocar interfone 2...',
        hintStyle: AppTextStyles.input.copyWith(color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.inputBackground,
        contentPadding: const EdgeInsets.all(14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.inputBorder, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.inputBorder, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildRodape(CartProvider cart) {
    final subtotal = cart.totalPrice;
    final taxa = _taxaEntrega(cart);
    final total = subtotal + taxa;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
        decoration: const BoxDecoration(
          color: AppColors.background,
          border: Border(top: BorderSide(color: AppColors.cardBorder)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (cart.items.isNotEmpty) ...[
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 84),
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: cart.items.length,
                  itemBuilder: (context, index) {
                    final item = cart.items[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${item.quantity}x ${item.product.name}',
                              style: AppTextStyles.subtituloLogin(size: 12.5).copyWith(color: AppColors.textDark),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            formatarPreco(item.subtotal),
                            style: AppTextStyles.subtituloLogin(size: 12.5).copyWith(color: AppColors.textDark),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(height: 1, color: AppColors.cardBorder),
              ),
            ],
            _buildLinhaResumo('Subtotal', valor: subtotal),
            if (_tipoEntrega == DeliveryType.delivery) ...[
              const SizedBox(height: 6),
              _buildLinhaResumo('Taxa de entrega', valor: taxa),
              FreeDeliveryHint(regra: cart.regraEntrega, subtotal: subtotal),
            ],
            if (_formaPagamento != null) ...[
              const SizedBox(height: 6),
              _buildLinhaResumo('Pagamento', texto: _formaPagamento!.label),
            ],
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(height: 1, color: AppColors.cardBorder),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total', style: AppTextStyles.tituloSecao(size: 16)),
                Text(formatarPreco(total), style: AppTextStyles.precoProduto.copyWith(fontSize: 20)),
              ],
            ),
            const SizedBox(height: 16),
            AppButton(
              label: 'CONFIRMAR PEDIDO',
              loading: _enviando,
              onPressed: _enviando ? null : (_podeConfirmar ? () => _confirmarPedido(cart) : null),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _enviando ? null : () => Navigator.of(context).pop(),
              child: Text('Voltar ao Carrinho', style: AppTextStyles.linkSenha(size: 14)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinhaResumo(String label, {double? valor, String? texto}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.subtituloLogin(size: 14).copyWith(color: AppColors.textLabel)),
        Text(
          texto ?? formatarPreco(valor ?? 0),
          style: AppTextStyles.subtituloLogin(size: 14).copyWith(
            color: AppColors.textDark,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
