import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../core/app_text_styles.dart';
import '../models/address.dart';
import '../models/user_profile.dart';
import '../navigation/app_router.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/order_history_provider.dart';
import 'address_form_screen.dart';
import 'edit_profile_screen.dart';

/// Aba "Perfil": dados do cliente logado (com edição), endereços salvos
/// (criar, editar, apagar, escolher o principal) e o botão de sair.
///
/// Tudo vem do [AuthProvider] e toda alteração passa por ele — assim a
/// finalização do pedido, que lê o mesmo provider, já enxerga o novo
/// endereço principal sem precisar recarregar nada.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  /// Ids dos endereços com uma ação em andamento (apagar / tornar
  /// principal) — o card troca os botões por um spinner.
  final Set<String> _processando = {};

  @override
  void initState() {
    super.initState();
    // Endereços carregam ao abrir o Perfil: busca a versão mais recente
    // no backend, mostrando a que já estava em memória enquanto isso.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AuthProvider>().recarregarPerfil();
    });
  }

  void _mostrarMensagem(String texto, {bool erro = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(texto),
        behavior: SnackBarBehavior.floating,
        backgroundColor: erro ? AppColors.errorText : AppColors.textDark,
      ));
  }

  Future<void> _editarDados() async {
    final salvou = await Navigator.of(context).push<bool>(
      MaterialPageRoute(fullscreenDialog: true, builder: (_) => const EditProfileScreen()),
    );
    if (salvou == true && mounted) _mostrarMensagem('Dados atualizados com sucesso');
  }

  Future<void> _abrirFormularioEndereco([Address? endereco]) async {
    final salvou = await Navigator.of(context).push<bool>(
      MaterialPageRoute(fullscreenDialog: true, builder: (_) => AddressFormScreen(endereco: endereco)),
    );
    if (salvou == true && mounted) {
      _mostrarMensagem(endereco == null ? 'Endereço salvo com sucesso' : 'Endereço atualizado com sucesso');
    }
  }

  /// Roda uma ação sobre um endereço com o card em loading, e mostra
  /// [sucesso] ou o erro devolvido pelo provider.
  Future<void> _acaoNoEndereco(String id, Future<String?> Function() acao, String sucesso) async {
    setState(() => _processando.add(id));
    final erro = await acao();
    if (!mounted) return;
    setState(() => _processando.remove(id));
    _mostrarMensagem(erro ?? sucesso, erro: erro != null);
  }

  Future<void> _confirmarPrincipal(Address endereco) async {
    final confirmou = await _confirmar(
      titulo: 'Definir como endereço principal?',
      mensagem: '${endereco.linhaPrincipal} passará a ser preenchido automaticamente ao finalizar seus pedidos.',
      acao: 'Definir',
    );
    if (confirmou != true || !mounted) return;
    final auth = context.read<AuthProvider>();
    await _acaoNoEndereco(
      endereco.id!,
      () => auth.definirEnderecoPrincipal(endereco.id!),
      'Endereço principal atualizado',
    );
  }

  Future<void> _confirmarRemocao(Address endereco, {required bool temOutros}) async {
    final confirmou = await _confirmar(
      titulo: 'Deletar endereço',
      mensagem: 'Tem certeza que deseja deletar este endereço?',
      aviso: endereco.isMain
          ? 'Este é seu endereço principal.${temOutros ? ' O próximo endereço da lista passará a ser o principal.' : ''}'
          : null,
      acao: 'Deletar',
      destrutiva: true,
    );
    if (confirmou != true || !mounted) return;
    final auth = context.read<AuthProvider>();
    await _acaoNoEndereco(endereco.id!, () => auth.removerEndereco(endereco.id!), 'Endereço removido');
  }

  Future<bool?> _confirmar({
    required String titulo,
    required String mensagem,
    String? aviso,
    required String acao,
    bool destrutiva = false,
  }) {
    final estiloTexto = AppTextStyles.subtituloLogin(size: 14).copyWith(color: AppColors.textDark, height: 1.4);
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(titulo, style: AppTextStyles.tituloSecao(size: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(mensagem, style: estiloTexto),
            if (aviso != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.errorBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.errorBorder),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.star_rounded, size: 18, color: AppColors.errorText),
                    const SizedBox(width: 8),
                    Expanded(child: Text(aviso, style: AppTextStyles.erro)),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancelar', style: AppTextStyles.linkSenha().copyWith(color: AppColors.textLabel)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              acao,
              style: AppTextStyles.linkSenha().copyWith(
                fontWeight: FontWeight.w700,
                color: destrutiva ? AppColors.errorText : AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmarSaida() async {
    // Só avisa do descarte quando há o que descartar.
    final carrinhoVazio = context.read<CartProvider>().isEmpty;
    final confirmou = await _confirmar(
      titulo: 'Sair da conta?',
      mensagem: carrinhoVazio
          ? 'Você precisará entrar novamente para fazer pedidos.'
          : 'Os itens do seu carrinho serão descartados.',
      acao: 'Sair',
    );
    if (confirmou != true || !mounted) return;
    _sair();
  }

  /// Limpa tudo o que é do usuário atual (carrinho, histórico da sessão,
  /// aba selecionada) antes de encerrar a sessão, para o próximo login
  /// começar do zero, e volta ao login sem deixar rota para trás.
  void _sair() {
    final navigator = Navigator.of(context);
    context.read<CartProvider>().clear();
    context.read<OrderHistoryProvider>().limpar();
    context.read<NavigationProvider>().reset();
    context.read<AuthProvider>().logout();
    navigator.pushNamedAndRemoveUntil(AppRouter.login, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthProvider>().usuario;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        automaticallyImplyLeading: false,
        title: Text('Meu Perfil', style: AppTextStyles.appBarTitulo),
      ),
      // Durante o logout o usuário vira null por um instante, antes da
      // tela sair — não há nada para mostrar nesse meio-tempo.
      body: usuario == null
          ? const SizedBox.shrink()
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                final erro = await context.read<AuthProvider>().recarregarPerfil();
                if (erro != null && mounted) _mostrarMensagem(erro, erro: true);
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildDadosPessoais(usuario),
                  const SizedBox(height: 28),
                  _buildCabecalhoEnderecos(),
                  const SizedBox(height: 12),
                  _buildEnderecos(usuario),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _confirmarSaida,
                      icon: const Icon(Icons.logout, color: AppColors.primary, size: 20),
                      label: Text('SAIR DA CONTA', style: AppTextStyles.botao.copyWith(color: AppColors.primary)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppColors.primary, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(child: Text('Maxi Massas Itápolis • App do Cliente', style: AppTextStyles.rodape())),
                ],
              ),
            ),
    );
  }

  Widget _buildDadosPessoais(UserProfile usuario) {
    final partes = usuario.name.trim().split(RegExp(r'\s+'));
    final iniciais = partes.first.isEmpty
        ? '?'
        : (partes.first[0] + (partes.length > 1 ? partes.last[0] : '')).toUpperCase();

    return _Cartao(
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.primary,
              child: Text(iniciais, style: AppTextStyles.botao.copyWith(fontSize: 18)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(usuario.name, style: AppTextStyles.tituloSecao(size: 17)),
                  const SizedBox(height: 2),
                  Text('Cliente Maxi Massas', style: AppTextStyles.subtituloLogin()),
                ],
              ),
            ),
            IconButton(
              onPressed: _editarDados,
              tooltip: 'Editar dados',
              style: IconButton.styleFrom(backgroundColor: AppColors.primary.withValues(alpha: 0.08)),
              icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 20),
            ),
          ],
        ),
        _LinhaInfo(icone: Icons.mail_outline, rotulo: 'E-mail', valor: usuario.email),
        _LinhaInfo(icone: Icons.phone_outlined, rotulo: 'Telefone', valor: usuario.phone),
      ],
    );
  }

  Widget _buildCabecalhoEnderecos() {
    return Row(
      children: [
        Expanded(child: Text('Endereços Salvos', style: AppTextStyles.tituloSecao(size: 16))),
        TextButton.icon(
          onPressed: () => _abrirFormularioEndereco(),
          style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
          icon: const Icon(Icons.add, size: 18, color: AppColors.primary),
          label: Text('Novo Endereço', style: AppTextStyles.linkSenha(size: 13).copyWith(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  Widget _buildEnderecos(UserProfile usuario) {
    final enderecos = usuario.addresses;

    // AnimatedSize: a lista cresce/encolhe suavemente ao salvar ou apagar.
    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: enderecos.isEmpty
          ? _Cartao(
              children: [
                Column(
                  children: [
                    const Icon(Icons.location_off_outlined, size: 36, color: AppColors.textMuted),
                    const SizedBox(height: 8),
                    Text('Nenhum endereço salvo', style: AppTextStyles.nomeProduto),
                    const SizedBox(height: 2),
                    Text(
                      'Salve um endereço para agilizar seus próximos pedidos.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.subtituloLogin(),
                    ),
                  ],
                ),
              ],
            )
          : Column(
              children: [
                for (final endereco in enderecos) ...[
                  _CartaoEndereco(
                    key: ValueKey(endereco.id),
                    endereco: endereco,
                    processando: _processando.contains(endereco.id),
                    onPrincipal: () => _confirmarPrincipal(endereco),
                    onEditar: () => _abrirFormularioEndereco(endereco),
                    onDeletar: () => _confirmarRemocao(endereco, temOutros: enderecos.length > 1),
                  ),
                  if (endereco != enderecos.last) const SizedBox(height: 10),
                ],
              ],
            ),
    );
  }
}

/// Card branco com borda sutil; os filhos são separados por divisórias.
class _Cartao extends StatelessWidget {
  const _Cartao({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1, color: AppColors.cardBorder),
              ),
          ],
        ],
      ),
    );
  }
}

class _CartaoEndereco extends StatelessWidget {
  const _CartaoEndereco({
    super.key,
    required this.endereco,
    required this.processando,
    required this.onPrincipal,
    required this.onEditar,
    required this.onDeletar,
  });

  final Address endereco;
  final bool processando;
  final VoidCallback onPrincipal;
  final VoidCallback onEditar;
  final VoidCallback onDeletar;

  @override
  Widget build(BuildContext context) {
    final principal = endereco.isMain;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.fromLTRB(6, 10, 6, 10),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: principal ? AppColors.primary.withValues(alpha: 0.5) : AppColors.cardBorder,
          width: principal ? 1.5 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: principal || processando ? null : onPrincipal,
            tooltip: principal ? 'Endereço principal' : 'Definir como principal',
            icon: Icon(
              principal ? Icons.star_rounded : Icons.star_outline_rounded,
              color: principal ? AppColors.primary : AppColors.textMuted,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (principal) ...[
                    Text(
                      'PRINCIPAL',
                      style: AppTextStyles.label(size: 10.5).copyWith(color: AppColors.primary, letterSpacing: 0.6),
                    ),
                    const SizedBox(height: 2),
                  ],
                  Text(endereco.linhaPrincipal, style: AppTextStyles.nomeProduto),
                  const SizedBox(height: 3),
                  Text(endereco.linhaSecundaria, style: AppTextStyles.subtituloLogin(size: 12.5)),
                ],
              ),
            ),
          ),
          if (processando)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
              ),
            )
          else ...[
            IconButton(
              onPressed: onEditar,
              tooltip: 'Editar endereço',
              icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.textLabel),
            ),
            IconButton(
              onPressed: onDeletar,
              tooltip: 'Deletar endereço',
              icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.errorText),
            ),
          ],
        ],
      ),
    );
  }
}

class _LinhaInfo extends StatelessWidget {
  const _LinhaInfo({required this.icone, required this.rotulo, required this.valor});

  final IconData icone;
  final String rotulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icone, size: 20, color: AppColors.textMuted),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(rotulo, style: AppTextStyles.label()),
              const SizedBox(height: 3),
              Text(valor, style: AppTextStyles.input.copyWith(height: 1.35)),
            ],
          ),
        ),
      ],
    );
  }
}
