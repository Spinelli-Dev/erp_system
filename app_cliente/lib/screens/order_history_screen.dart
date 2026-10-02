import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../core/app_text_styles.dart';
import '../core/formatters.dart';
import '../models/date_filter.dart';
import '../models/delivery_type.dart';
import '../models/order_confirmation.dart';
import '../models/order_status.dart';
import '../models/payment_method.dart';
import '../navigation/app_navigation.dart';
import '../providers/cart_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/order_history_provider.dart';
import '../providers/product_provider.dart';
import '../services/whatsapp_service.dart';
import '../widgets/category_chip.dart';

/// Aba "Meus Pedidos" (ver `MainShell`): lista os pedidos do cliente, mais
/// recente primeiro, com o status atualizado pelos gestores. O `MainShell`
/// busca de novo no backend sempre que a aba abre, e dá para puxar a
/// lista para atualizar. Também é para onde leva o botão "Ver Meus
/// Pedidos" da tela de confirmação.
///
/// Acima da lista, uma barra de chips filtra por período (padrão: últimos
/// 7 dias). O filtro vive no [OrderHistoryProvider]: continua o mesmo
/// enquanto o usuário está na aba e volta ao padrão quando ele sai dela
/// (ver `MainShell`) ou faz logout.
class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        automaticallyImplyLeading: false,
        title: Text('Meus Pedidos', style: AppTextStyles.appBarTitulo),
      ),
      body: Consumer<OrderHistoryProvider>(
        builder: (context, historico, _) {
          if (historico.isEmpty) {
            if (historico.carregando) return const Center(child: CircularProgressIndicator());
            if (historico.erro != null) return _buildErro(historico);
            return _buildVazio();
          }

          final pedidos = historico.pedidosFiltrados;
          return Column(
            children: [
              _BarraFiltros(historico: historico),
              if (historico.carregando) const LinearProgressIndicator(minHeight: 2),
              Expanded(
                // Puxar para baixo busca o status mais recente no backend.
                child: RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: historico.carregar,
                  // Fade ao trocar de filtro, em vez da lista "pular".
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: KeyedSubtree(
                      key: ValueKey('${historico.filtro}-${historico.periodoPersonalizado}'),
                      child: pedidos.isEmpty
                          ? _buildVazioNoPeriodo(historico)
                          : ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(16),
                              itemCount: pedidos.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) => _PedidoTile(pedido: pedidos[index]),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
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
            const Icon(Icons.receipt_long_outlined, size: 56, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text('Nenhum pedido ainda', style: AppTextStyles.tituloSecao(size: 18)),
            const SizedBox(height: 6),
            Text(
              'Os pedidos que você fizer aparecem aqui.',
              textAlign: TextAlign.center,
              style: AppTextStyles.subtituloLogin(size: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErro(OrderHistoryProvider historico) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 56, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text('Pedidos indisponíveis', style: AppTextStyles.tituloSecao(size: 18)),
            const SizedBox(height: 6),
            Text(historico.erro!, textAlign: TextAlign.center, style: AppTextStyles.subtituloLogin(size: 14)),
            const SizedBox(height: 12),
            TextButton(
              onPressed: historico.carregar,
              child: Text('Tentar novamente', style: AppTextStyles.linkSenha(size: 14)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVazioNoPeriodo(OrderHistoryProvider historico) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.event_busy_outlined, size: 56, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text('Nenhum pedido neste período', style: AppTextStyles.tituloSecao(size: 18)),
            const SizedBox(height: 6),
            Text(
              'Tente um período maior para ver seus pedidos anteriores.',
              textAlign: TextAlign.center,
              style: AppTextStyles.subtituloLogin(size: 14),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => historico.selecionarFiltro(DateFilter.all),
              child: Text('Ver todos os pedidos', style: AppTextStyles.linkSenha(size: 14)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Chips de período em scroll horizontal — mesmo visual da barra de
/// categorias da aba Produtos ([CategoryChip]).
class _BarraFiltros extends StatelessWidget {
  const _BarraFiltros({required this.historico});

  final OrderHistoryProvider historico;

  Future<void> _escolherPeriodo(BuildContext context) async {
    final hoje = DateTime.now();
    final periodo = await showDateRangePicker(
      context: context,
      firstDate: DateTime(hoje.year - 5),
      lastDate: hoje,
      initialDateRange: historico.periodoPersonalizado,
      helpText: 'Selecione o período',
      saveText: 'Aplicar',
      cancelText: 'Cancelar',
      confirmText: 'OK',
      fieldStartLabelText: 'Data inicial',
      fieldEndLabelText: 'Data final',
      errorFormatText: 'Data inválida',
      errorInvalidText: 'Fora do intervalo permitido',
      errorInvalidRangeText: 'Período inválido',
    );
    if (periodo != null) historico.selecionarPeriodo(periodo);
  }

  String _rotulo(DateFilter filtro) {
    final periodo = historico.periodoPersonalizado;
    if (filtro != DateFilter.custom || periodo == null) return filtro.label;

    String diaMes(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
    return '${diaMes(periodo.start)} – ${diaMes(periodo.end)}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: DateFilter.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filtro = DateFilter.values[index];
          return CategoryChip(
            label: _rotulo(filtro),
            selected: filtro == historico.filtro,
            onTap: () => filtro == DateFilter.custom
                ? _escolherPeriodo(context)
                : historico.selecionarFiltro(filtro),
          );
        },
      ),
    );
  }
}

/// Card de um pedido no histórico. Tocar nele expande/recolhe os
/// detalhes — itens comprados, endereço de entrega (ou local de
/// retirada) e o atalho para falar com a loja no WhatsApp. O resto do
/// card (cabeçalho, resumo, total, "Repetir pedido") fica sempre visível.
class _PedidoTile extends StatefulWidget {
  const _PedidoTile({required this.pedido});

  final OrderConfirmation pedido;

  @override
  State<_PedidoTile> createState() => _PedidoTileState();
}

class _PedidoTileState extends State<_PedidoTile> {
  bool _expandido = false;
  bool _repetindo = false;

  Future<void> _repetirPedido() async {
    // Capturados antes do await: o card pode sair da tela (ex.: troca de
    // filtro) enquanto o cardápio carrega.
    final produtos = context.read<ProductProvider>();
    final cart = context.read<CartProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final irParaCarrinho = AppNavigation.acaoIrParaAba(context, AppTab.carrinho);

    setState(() => _repetindo = true);
    // A disponibilidade é conferida no cardápio atual, não no pedido
    // antigo — por isso ele precisa estar carregado.
    await produtos.garantirCarregado();
    if (mounted) setState(() => _repetindo = false);

    if (produtos.status != ProductLoadStatus.loaded) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          content: Text('Não foi possível conferir o cardápio. Verifique sua conexão e tente novamente.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.errorText,
        ));
      return;
    }

    final resultado = cart.repetirItens(widget.pedido.items, produtos.products);
    HapticFeedback.lightImpact();

    if (resultado.indisponiveis.isEmpty) {
      final n = resultado.unidadesAdicionadas;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text('$n ${n == 1 ? 'item adicionado' : 'itens adicionados'} ao carrinho'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.textDark,
          action: SnackBarAction(label: 'VER CARRINHO', textColor: Colors.white, onPressed: irParaCarrinho),
        ));
      return;
    }

    if (!mounted) return;
    final verCarrinho = await showDialog<bool>(
      context: context,
      builder: (_) => _AvisoIndisponiveis(resultado: resultado),
    );
    if (verCarrinho == true) irParaCarrinho();
  }

  @override
  Widget build(BuildContext context) {
    final pedido = widget.pedido;
    final quantidadeItens = pedido.items.fold<int>(0, (soma, item) => soma + item.quantity);

    return Material(
      color: AppColors.cardBackground,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => setState(() => _expandido = !_expandido),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(pedido.orderId, style: AppTextStyles.tituloSecao(size: 15)),
                  _buildBadgeStatus(),
                ],
              ),
              const SizedBox(height: 4),
              Text(formatarDataHora(pedido.orderDate), style: AppTextStyles.descricaoProduto),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    pedido.deliveryType == DeliveryType.delivery
                        ? Icons.delivery_dining_outlined
                        : Icons.storefront_outlined,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 6),
                  Text(pedido.deliveryType.label, style: AppTextStyles.descricaoProduto),
                  const SizedBox(width: 14),
                  const Icon(Icons.shopping_bag_outlined, size: 16, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  Text(
                    '$quantidadeItens ${quantidadeItens == 1 ? 'item' : 'itens'}',
                    style: AppTextStyles.descricaoProduto,
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 200),
                    turns: _expandido ? 0.5 : 0,
                    child: const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: AppColors.textMuted),
                  ),
                ],
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                alignment: Alignment.topCenter,
                child: _expandido ? _buildDetalhes(pedido) : const SizedBox(width: double.infinity),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1, color: AppColors.cardBorder),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(pedido.paymentMethod.label, style: AppTextStyles.subtituloLogin(size: 13)),
                  Text(formatarPreco(pedido.total), style: AppTextStyles.precoProduto.copyWith(fontSize: 16)),
                ],
              ),
              const SizedBox(height: 12),
              _buildBotaoRepetir(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _abrirWhatsApp() async {
    final pedido = widget.pedido;
    final messenger = ScaffoldMessenger.of(context);
    final telefone = pedido.pickupLocation.phoneNumber;

    final abriu = await WhatsAppService.abrirConversa(
      telefone: telefone,
      mensagem: 'Olá! Preciso de ajuda com o pedido ${pedido.orderId}, '
          'feito em ${formatarDataHora(pedido.orderDate)}.',
    );
    if (abriu) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('Não foi possível abrir o WhatsApp. Fale com a loja pelo $telefone.'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textDark,
      ));
  }

  Widget _buildDetalhes(OrderConfirmation pedido) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1, color: AppColors.cardBorder),
          const SizedBox(height: 12),
          _buildRotuloSecao('Itens do pedido'),
          const SizedBox(height: 8),
          for (final item in pedido.items) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.product.name,
                        style: AppTextStyles.nomeProduto,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${item.quantity}x ${formatarPreco(item.product.price)}',
                        style: AppTextStyles.descricaoProduto,
                      ),
                    ],
                  ),
                ),
                Text(formatarPreco(item.subtotal), style: AppTextStyles.precoProduto.copyWith(fontSize: 13)),
              ],
            ),
            if (item != pedido.items.last) const SizedBox(height: 10),
          ],
          const SizedBox(height: 16),
          _buildEntrega(pedido),
          const SizedBox(height: 14),
          _buildBotaoWhatsApp(),
        ],
      ),
    );
  }

  Widget _buildRotuloSecao(String texto) => Text(
        texto.toUpperCase(),
        style: AppTextStyles.label(size: 10.5).copyWith(color: AppColors.textMuted, letterSpacing: 0.6),
      );

  /// Onde o pedido vai ser entregue — ou, na retirada, onde buscar —
  /// para o cliente conferir qual endereço usou.
  Widget _buildEntrega(OrderConfirmation pedido) {
    final endereco = pedido.deliveryAddress;
    final entrega = pedido.deliveryType == DeliveryType.delivery && endereco != null;
    final loja = pedido.pickupLocation;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRotuloSecao(entrega ? 'Endereço de entrega' : 'Retirada no local'),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.inputBackground,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                entrega ? Icons.location_on_outlined : Icons.storefront_outlined,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entrega ? endereco.linhaPrincipal : loja.name, style: AppTextStyles.nomeProduto),
                    const SizedBox(height: 3),
                    Text(
                      entrega ? endereco.linhaSecundaria : loja.address,
                      style: AppTextStyles.subtituloLogin(size: 12.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBotaoWhatsApp() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Precisa cancelar, corrigir o endereço ou tirar uma dúvida?',
          style: AppTextStyles.subtituloLogin(size: 12.5),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 40,
          child: TextButton.icon(
            onPressed: _abrirWhatsApp,
            icon: const Icon(Icons.chat_outlined, size: 18, color: AppColors.success),
            label: Text(
              'FALAR COM A LOJA NO WHATSAPP',
              style: AppTextStyles.botao.copyWith(color: AppColors.success, fontSize: 13),
            ),
            style: TextButton.styleFrom(
              backgroundColor: AppColors.success.withValues(alpha: 0.08),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBotaoRepetir() {
    return SizedBox(
      width: double.infinity,
      height: 40,
      child: OutlinedButton.icon(
        onPressed: _repetindo ? null : _repetirPedido,
        icon: _repetindo
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
              )
            : const Icon(Icons.replay_rounded, size: 18, color: AppColors.primary),
        label: Text(
          'REPETIR PEDIDO',
          style: AppTextStyles.botao.copyWith(color: AppColors.primary, fontSize: 13),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget _buildBadgeStatus() {
    final status = widget.pedido.status;
    // Verde enquanto o pedido anda bem, vermelho se cancelado, cinza quando acabou.
    final cor = switch (status) {
      OrderStatus.cancelado => AppColors.errorText,
      OrderStatus.concluido => AppColors.textLabel,
      _ => AppColors.success,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: AppTextStyles.chip(selecionado: false).copyWith(
          color: cor,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Aviso mostrado quando parte (ou todo) o pedido repetido não pôde entrar
/// no carrinho. Devolve `true` se o usuário escolher ir para o carrinho.
class _AvisoIndisponiveis extends StatelessWidget {
  const _AvisoIndisponiveis({required this.resultado});

  final RepeticaoPedido resultado;

  @override
  Widget build(BuildContext context) {
    final n = resultado.unidadesAdicionadas;
    final estiloTexto = AppTextStyles.subtituloLogin(size: 14).copyWith(color: AppColors.textDark, height: 1.4);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        resultado.nadaAdicionado ? 'Itens indisponíveis' : 'Alguns itens estão indisponíveis',
        style: AppTextStyles.tituloSecao(size: 16),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            resultado.nadaAdicionado
                ? 'Nenhum item deste pedido está disponível no momento:'
                : '$n ${n == 1 ? 'item foi adicionado' : 'itens foram adicionados'} ao carrinho. '
                    'Não foi possível adicionar:',
            style: estiloTexto,
          ),
          const SizedBox(height: 10),
          for (final nome in resultado.indisponiveis)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(Icons.remove_shopping_cart_outlined, size: 16, color: AppColors.errorText),
                  const SizedBox(width: 8),
                  Expanded(child: Text(nome, style: estiloTexto.copyWith(fontWeight: FontWeight.w600))),
                ],
              ),
            ),
        ],
      ),
      actions: resultado.nadaAdicionado
          ? [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Entendi', style: AppTextStyles.linkSenha()),
              ),
            ]
          : [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Continuar', style: AppTextStyles.linkSenha().copyWith(color: AppColors.textLabel)),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('Ver carrinho', style: AppTextStyles.linkSenha().copyWith(fontWeight: FontWeight.w700)),
              ),
            ],
    );
  }
}
