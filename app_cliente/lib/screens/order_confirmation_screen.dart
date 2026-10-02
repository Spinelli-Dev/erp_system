import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../core/app_colors.dart';
import '../core/app_text_styles.dart';
import '../core/formatters.dart';
import '../models/delivery_type.dart';
import '../models/franchise_info.dart';
import '../models/order_confirmation.dart';
import '../models/payment_method.dart';
import '../navigation/app_navigation.dart';
import '../providers/navigation_provider.dart';
import '../widgets/app_button.dart';

/// Tela final do fluxo de compra: confirma que o pedido foi recebido,
/// resume tudo o que foi decidido no checkout (entrega, itens, valores,
/// pagamento) e oferece só ações de "ir para frente" — fazer um novo
/// pedido, ver o histórico ou compartilhar. Nada aqui é editável (o
/// pedido já foi enviado ao backend); a única exceção, "Editar
/// endereço", não edita nada nesta tela — só orienta a falar com a loja.
///
/// Não recebe mais parâmetros soltos: tudo vem de um único
/// [OrderConfirmation], montado pela tela de checkout antes de limpar o
/// carrinho — assim esta tela funciona sozinha, sem depender de nenhum
/// provider (inclusive se o usuário voltar para cá depois).
class OrderConfirmationScreen extends StatefulWidget {
  const OrderConfirmationScreen({super.key, required this.pedido});

  final OrderConfirmation pedido;

  @override
  State<OrderConfirmationScreen> createState() => _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends State<OrderConfirmationScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  late final Animation<double> _escalaCheck = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _compartilharPedido() async {
    final texto = _montarTextoCompartilhamento(widget.pedido);
    try {
      await Share.share(texto, subject: 'Pedido ${widget.pedido.orderId} — Maxi Massas');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o compartilhamento neste dispositivo.')),
      );
    }
  }

  void _avisarQueNaoEditaAqui(FranchiseInfo franquia) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Pedido já confirmado', style: AppTextStyles.tituloSecao(size: 16)),
        content: Text(
          'Este pedido já foi enviado para a loja, então o endereço não pode ser alterado por aqui. '
          'Para trocar, fale com a gente o quanto antes pelo telefone/WhatsApp ${franquia.phoneNumber}.',
          style: AppTextStyles.subtituloLogin(size: 14).copyWith(color: AppColors.textDark, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Entendi', style: AppTextStyles.linkSenha()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pedido = widget.pedido;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        // Confirmação final: sem botão de voltar (não tem para onde
        // "desfazer" — o pedido já foi enviado).
        automaticallyImplyLeading: false,
        title: Text('Pedido Confirmado', style: AppTextStyles.appBarTitulo),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildConfirmacaoVisual(pedido),
              const SizedBox(height: 22),
              _buildTempoEstimado(pedido),
              const SizedBox(height: 18),
              _buildSecao(titulo: 'Entrega', child: _buildResumoEntrega(pedido)),
              const SizedBox(height: 16),
              _buildSecao(titulo: 'Itens do pedido', child: _buildItens(pedido)),
              const SizedBox(height: 16),
              _buildSecao(titulo: 'Valores', child: _buildValores(pedido)),
              const SizedBox(height: 16),
              _buildSecao(titulo: 'Pagamento', child: _buildPagamento(pedido)),
              if (pedido.specialObservations.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildSecao(
                  titulo: 'Observações',
                  child: Text(
                    pedido.specialObservations,
                    style: AppTextStyles.subtituloLogin(size: 13).copyWith(color: AppColors.textDark),
                  ),
                ),
              ],
              const SizedBox(height: 26),
              _buildBotoes(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmacaoVisual(OrderConfirmation pedido) {
    return Column(
      children: [
        ScaleTransition(
          scale: _escalaCheck,
          child: Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded, color: AppColors.success, size: 52),
          ),
        ),
        const SizedBox(height: 18),
        Text('Seu pedido foi recebido!', style: AppTextStyles.tituloLogin(size: 22), textAlign: TextAlign.center),
        const SizedBox(height: 4),
        Text(
          'Já começamos a separar tudo com carinho.',
          style: AppTextStyles.subtituloLogin(size: 14),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 18),
        Text(
          pedido.orderId,
          style: AppTextStyles.tituloLogin(size: 34).copyWith(color: AppColors.primary, fontWeight: FontWeight.w900),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(formatarDataHora(pedido.orderDate), style: AppTextStyles.rodape(size: 12)),
      ],
    );
  }

  Widget _buildTempoEstimado(OrderConfirmation pedido) {
    final previsao = pedido.orderDate.add(Duration(minutes: pedido.estimatedTimeMinutes));
    final mensagem = pedido.deliveryType == DeliveryType.delivery
        ? 'Seu pedido chegará em aproximadamente ${pedido.estimatedTimeMinutes} minutos.'
        : 'Sua compra estará pronta em ${pedido.estimatedTimeMinutes} minutos — por volta das ${formatarHora(previsao)}.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.timer_outlined, color: AppColors.success),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              mensagem,
              style: AppTextStyles.subtituloLogin(size: 13).copyWith(
                color: AppColors.textDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecao({required String titulo, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: AppTextStyles.label(size: 13)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildResumoEntrega(OrderConfirmation pedido) {
    if (pedido.deliveryType == DeliveryType.delivery) {
      final endereco = pedido.deliveryAddress;
      final complemento = endereco != null && endereco.complement.trim().isNotEmpty
          ? ' — ${endereco.complement.trim()}'
          : '';
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLinhaInfo(Icons.local_shipping_outlined, 'Receber no Endereço'),
          const SizedBox(height: 10),
          if (endereco != null)
            Text(
              '${endereco.street}, ${endereco.number}$complemento\n${endereco.neighborhood}',
              style: AppTextStyles.subtituloLogin(size: 13).copyWith(color: AppColors.textDark, height: 1.4),
            ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _avisarQueNaoEditaAqui(pedido.pickupLocation),
              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
              icon: const Icon(Icons.edit_outlined, size: 15, color: AppColors.primary),
              label: Text('Editar endereço', style: AppTextStyles.linkSenha(size: 13)),
            ),
          ),
        ],
      );
    }

    final franquia = pedido.pickupLocation;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLinhaInfo(Icons.storefront_outlined, 'Retirar no Local — ${franquia.name}'),
        const SizedBox(height: 10),
        _buildLinhaInfo(Icons.location_on_outlined, franquia.address),
        const SizedBox(height: 6),
        _buildLinhaInfo(Icons.schedule_outlined, franquia.hours),
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

  Widget _buildItens(OrderConfirmation pedido) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 220),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const ClampingScrollPhysics(),
        itemCount: pedido.items.length,
        separatorBuilder: (_, __) => const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Divider(height: 1, color: AppColors.cardBorder),
        ),
        itemBuilder: (context, index) {
          final item = pedido.items[index];
          return Row(
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
              Text(formatarPreco(item.subtotal), style: AppTextStyles.precoProduto.copyWith(fontSize: 14)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildValores(OrderConfirmation pedido) {
    return Column(
      children: [
        _buildLinhaValor('Subtotal', pedido.subtotal),
        if (pedido.deliveryType == DeliveryType.delivery) ...[
          const SizedBox(height: 6),
          _buildLinhaValor('Taxa de entrega', pedido.deliveryFee),
        ],
        if (pedido.discount > 0) ...[
          const SizedBox(height: 6),
          _buildLinhaValor('Desconto', -pedido.discount, corValor: AppColors.success),
        ],
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Divider(height: 1, color: AppColors.cardBorder),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Total', style: AppTextStyles.tituloSecao(size: 16)),
            Text(
              formatarPreco(pedido.total),
              style: AppTextStyles.precoProduto.copyWith(fontSize: 20, color: AppColors.success),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLinhaValor(String label, double valor, {Color? corValor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.subtituloLogin(size: 14).copyWith(color: AppColors.textLabel)),
        Text(
          formatarPreco(valor),
          style: AppTextStyles.subtituloLogin(size: 14).copyWith(
            color: corValor ?? AppColors.textDark,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildPagamento(OrderConfirmation pedido) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(pedido.paymentMethod.icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(pedido.paymentMethod.label, style: AppTextStyles.nomeProduto),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          pedido.paymentInstructions,
          style: AppTextStyles.subtituloLogin(size: 13).copyWith(color: AppColors.textDark, height: 1.5),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.support_agent_outlined, size: 16, color: AppColors.textMuted),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Dúvidas sobre o pedido? Fale conosco: ${pedido.pickupLocation.phoneNumber}',
                style: AppTextStyles.descricaoProduto,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBotoes() {
    return Column(
      children: [
        AppButton(
          label: 'FAZER NOVO PEDIDO',
          onPressed: () => AppNavigation.irParaAba(context, AppTab.produtos),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => AppNavigation.irParaAba(context, AppTab.pedidos),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: AppColors.primary, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('VER MEUS PEDIDOS', style: AppTextStyles.botao.copyWith(color: AppColors.primary)),
          ),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _compartilharPedido,
          icon: const Icon(Icons.share_outlined, size: 18, color: AppColors.textLabel),
          label: Text(
            'Compartilhar Pedido',
            style: AppTextStyles.linkSenha(size: 14).copyWith(color: AppColors.textLabel),
          ),
        ),
      ],
    );
  }
}

String _montarTextoCompartilhamento(OrderConfirmation pedido) {
  final buffer = StringBuffer()
    ..writeln('Pedido ${pedido.orderId} — Maxi Massas Itápolis')
    ..writeln(formatarDataHora(pedido.orderDate))
    ..writeln();
  for (final item in pedido.items) {
    buffer.writeln('${item.quantity}x ${item.product.name} — ${formatarPreco(item.subtotal)}');
  }
  buffer
    ..writeln()
    ..writeln('Total: ${formatarPreco(pedido.total)}')
    ..writeln(pedido.deliveryType == DeliveryType.delivery ? 'Entrega no endereço' : 'Retirada no local');
  return buffer.toString();
}
