import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../providers/cart_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/order_history_provider.dart';
import '../screens/cart_screen.dart';
import '../screens/order_history_screen.dart';
import '../screens/products_screen.dart';
import '../screens/profile_screen.dart';
import 'atualizar_cardapio.dart';

/// Tela principal depois do login: as quatro abas (Produtos, Carrinho,
/// Meus Pedidos, Perfil) com a barra de navegação inferior.
///
/// Navegação "flat": trocar de aba não empilha rota nem mostra botão
/// voltar. As abas ficam vivas num [IndexedStack] depois da primeira
/// visita, então voltar a uma aba mantém rolagem, filtro de categoria e
/// pedidos expandidos. A aba selecionada vem do [NavigationProvider], para
/// outras telas poderem trocá-la.
///
/// O que muda no servidor é buscado de novo sem trocar a tela por um
/// "carregando": o histórico ao abrir "Meus Pedidos" e o cardápio (com o
/// estoque) ao abrir Produtos ou Carrinho, ao voltar para o app e a cada
/// [intervaloCardapio] enquanto uma dessas abas está aberta.
class MainShell extends StatefulWidget {
  const MainShell({super.key, this.abaInicial = AppTab.produtos});

  final AppTab abaInicial;

  @override
  State<MainShell> createState() => _MainShellState();
}

/// De quanto em quanto tempo o cardápio é buscado de novo com o app aberto
/// em Produtos ou Carrinho.
const intervaloCardapio = Duration(minutes: 1);

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  late final NavigationProvider _navegacao = context.read<NavigationProvider>();

  Timer? _relogioCardapio;

  bool get _abaComEstoque => _navegacao.abaAtual == AppTab.produtos || _navegacao.abaAtual == AppTab.carrinho;

  /// Abas já abertas ao menos uma vez — só elas são construídas, para não
  /// montar (e disparar cargas de) telas que o usuário nem visitou.
  final Set<AppTab> _visitadas = {};

  late AppTab _abaAnterior = widget.abaInicial;

  @override
  void initState() {
    super.initState();
    _navegacao.registrarShell(widget.abaInicial);
    _navegacao.addListener(_aoTrocarAba);
    _visitadas.add(widget.abaInicial);
    if (widget.abaInicial == AppTab.pedidos) _atualizarPedidos();
    WidgetsBinding.instance.addObserver(this);
    _relogioCardapio = Timer.periodic(intervaloCardapio, (_) {
      if (_abaComEstoque) _atualizarCardapio();
    });
  }

  /// App voltou para a frente (ex.: o cliente foi ao WhatsApp e voltou):
  /// o estoque pode ter mudado enquanto ele estava fora.
  @override
  void didChangeAppLifecycleState(AppLifecycleState estado) {
    if (estado == AppLifecycleState.resumed && _abaComEstoque) _atualizarCardapio();
  }

  void _atualizarCardapio() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) atualizarCardapioECarrinho(context);
    });
  }

  /// Busca o histórico no backend a cada vez que "Meus Pedidos" abre, para
  /// mostrar o status mais recente (os gestores mudam pelo sistema web).
  /// Depois do frame: o provider notifica, e não pode durante um build.
  void _atualizarPedidos() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<OrderHistoryProvider>().carregar();
    });
  }

  @override
  void dispose() {
    _relogioCardapio?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _navegacao.removeListener(_aoTrocarAba);
    _navegacao.removerShell();
    super.dispose();
  }

  void _aoTrocarAba() {
    final aba = _navegacao.abaAtual;
    // O filtro de período de "Meus Pedidos" só vale enquanto o usuário
    // está na aba: saiu dela, volta ao padrão.
    if (_abaAnterior == AppTab.pedidos && aba != AppTab.pedidos) {
      context.read<OrderHistoryProvider>().resetarFiltro();
    }
    if (aba == AppTab.pedidos && _abaAnterior != AppTab.pedidos) _atualizarPedidos();
    if (_abaComEstoque && aba != _abaAnterior) _atualizarCardapio();
    _abaAnterior = aba;
    // A SnackBar de "produto adicionado" (com o atalho VER CARRINHO)
    // perde o sentido quando o usuário já está no carrinho.
    if (aba == AppTab.carrinho) ScaffoldMessenger.of(context).clearSnackBars();
    setState(() => _visitadas.add(aba));
  }

  Widget _telaDa(AppTab aba) {
    switch (aba) {
      case AppTab.produtos:
        return const ProductsScreen();
      case AppTab.carrinho:
        return const CartScreen();
      case AppTab.pedidos:
        return const OrderHistoryScreen();
      case AppTab.perfil:
        return const ProfileScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final abaAtual = _navegacao.abaAtual;

    // Botão voltar do Android: fora da aba de produtos, volta para ela;
    // na aba de produtos, sai do app normalmente.
    return PopScope(
      canPop: abaAtual == AppTab.produtos,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _navegacao.selecionar(AppTab.produtos);
      },
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        body: _AbasComFade(
          index: abaAtual.index,
          children: [
            for (final aba in AppTab.values) _visitadas.contains(aba) ? _telaDa(aba) : const SizedBox.shrink(),
          ],
        ),
        bottomNavigationBar: _BarraNavegacao(
          abaAtual: abaAtual,
          onSelecionar: _navegacao.selecionar,
        ),
      ),
    );
  }
}

/// [IndexedStack] com um fade curto a cada troca de aba. Não usa
/// `AnimatedSwitcher` porque ele descartaria a aba anterior (e o estado
/// dela) — aqui todas continuam montadas, só a visível é animada.
class _AbasComFade extends StatefulWidget {
  const _AbasComFade({required this.index, required this.children});

  final int index;
  final List<Widget> children;

  @override
  State<_AbasComFade> createState() => _AbasComFadeState();
}

class _AbasComFadeState extends State<_AbasComFade> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
    value: 1,
  );

  @override
  void didUpdateWidget(_AbasComFade oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _controller, curve: Curves.easeOut),
      child: IndexedStack(
        index: widget.index,
        children: [
          // Pausa animações (skeletons, spinners) das abas escondidas.
          for (var i = 0; i < widget.children.length; i++)
            TickerMode(enabled: i == widget.index, child: widget.children[i]),
        ],
      ),
    );
  }
}

class _BarraNavegacao extends StatelessWidget {
  const _BarraNavegacao({required this.abaAtual, required this.onSelecionar});

  final AppTab abaAtual;
  final ValueChanged<AppTab> onSelecionar;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: AppColors.background,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          height: 66,
          indicatorColor: AppColors.primary.withValues(alpha: 0.1),
          labelTextStyle: WidgetStateProperty.resolveWith(
            (estados) => GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: estados.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
              color: estados.contains(WidgetState.selected) ? AppColors.primary : AppColors.textMuted,
            ),
          ),
          iconTheme: WidgetStateProperty.resolveWith(
            (estados) => IconThemeData(
              size: 24,
              color: estados.contains(WidgetState.selected) ? AppColors.primary : AppColors.textMuted,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: abaAtual.index,
          onDestinationSelected: (index) => onSelecionar(AppTab.values[index]),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.storefront_outlined),
              selectedIcon: Icon(Icons.storefront),
              label: 'Produtos',
              tooltip: 'Produtos',
            ),
            NavigationDestination(
              icon: _IconeCarrinho(selecionado: false),
              selectedIcon: _IconeCarrinho(selecionado: true),
              label: 'Carrinho',
              tooltip: 'Carrinho',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long),
              label: 'Meus Pedidos',
              tooltip: 'Meus Pedidos',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Perfil',
              tooltip: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}

/// Ícone do carrinho com o badge de quantidade. Usa `select` para só
/// este ícone reconstruir quando o total de itens muda — não a barra
/// nem o shell inteiro.
class _IconeCarrinho extends StatelessWidget {
  const _IconeCarrinho({required this.selecionado});

  final bool selecionado;

  @override
  Widget build(BuildContext context) {
    final quantidade = context.select<CartProvider, int>((cart) => cart.totalItems);

    return Badge(
      isLabelVisible: quantidade > 0,
      backgroundColor: AppColors.primary,
      textColor: Colors.white,
      offset: const Offset(8, -6),
      label: Text(
        quantidade > 99 ? '99+' : '$quantidade',
        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700),
      ),
      child: Icon(selecionado ? Icons.shopping_cart : Icons.shopping_cart_outlined),
    );
  }
}
