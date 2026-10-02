import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../core/app_text_styles.dart';
import '../providers/auth_provider.dart';
import '../providers/navigation_provider.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import '../widgets/decorative_banner.dart';
import 'forgot_password_screen.dart';
import 'signup_screen.dart';

/// Tela de login do app de compras Maxi Massas Itápolis, para clientes.
///
/// Layout único, pensado para celular (não é uma versão responsiva do
/// site administrativo): banner vermelho da marca com o logo no topo e,
/// por baixo, um cartão branco de cantos arredondados com o formulário —
/// mesma paleta e tipografia (Inter) usadas em backend/wwwroot/css/componentes.css.
///
/// A restrição de largura de celular (com a faixa cinza ao redor quando a
/// janela é mais larga, ex.: Chrome de desktop) é aplicada globalmente por
/// `MobileFrame` em main.dart — esta tela não precisa se preocupar com isso.
///
/// [onLogin] deve retornar `null` em caso de sucesso, ou uma mensagem de
/// erro (ex.: "E-mail ou senha incorretos.") em caso de falha. Por padrão,
/// usa o [AuthProvider] (que abre a sessão usada pelas abas).
///
/// [destino] é a rota da aba para abrir depois de entrar — preenchida
/// pelo `AppRouter` quando um deep link chega sem sessão ativa.
class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    this.onLogin,
    this.onEsqueciSenha,
    this.onCriarConta,
    this.destino,
  });

  final Future<String?> Function(String email, String senha)? onLogin;
  final VoidCallback? onEsqueciSenha;
  final VoidCallback? onCriarConta;
  final String? destino;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();

  bool _senhaVisivel = false;
  bool _carregando = false;
  String? _mensagemErro;
  String? _mensagemSucesso;

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  String? _validarEmail(String? valor) {
    final email = valor?.trim() ?? '';
    if (email.isEmpty) return 'Informe seu e-mail';
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!regex.hasMatch(email)) return 'Informe um e-mail válido';
    return null;
  }

  // Só exige a senha preenchida: quem confere é o servidor. A regra de
  // formato (validarSenhaNova) vale para senhas novas; aplicá-la aqui
  // barraria quem criou a conta quando a regra era outra.
  String? _validarSenha(String? valor) => (valor == null || valor.isEmpty) ? 'Informe sua senha' : null;

  Future<void> _entrar() async {
    setState(() {
      _mensagemErro = null;
      _mensagemSucesso = null;
    });
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _carregando = true);

    final erro = widget.onLogin != null
        ? await widget.onLogin!(_emailController.text.trim(), _senhaController.text)
        : await context.read<AuthProvider>().login(_emailController.text.trim(), _senhaController.text);

    if (!mounted) return;
    setState(() {
      _carregando = false;
      _mensagemErro = erro;
    });

    if (erro == null) {
      Navigator.of(context).pushReplacementNamed(widget.destino ?? AppTab.produtos.rota);
    }
  }

  /// Abre o "Esqueci minha senha" com o e-mail já digitado; se a senha for
  /// trocada, a tela devolve o e-mail e o login fica pronto para entrar.
  Future<void> _abrirEsqueciSenha() async {
    final email = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => ForgotPasswordScreen(emailInicial: _emailController.text.trim())),
    );
    if (!mounted || email == null) return;
    setState(() {
      _emailController.text = email;
      _senhaController.clear();
      _mensagemErro = null;
      _mensagemSucesso = 'Senha alterada! Entre com a nova senha.';
    });
  }

  void _abrirCadastro() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => SignupScreen(destino: widget.destino)));
  }

  @override
  Widget build(BuildContext context) {
    // A largura de celular já é garantida globalmente pelo `MobileFrame`
    // (ver main.dart) — esta tela só cuida do próprio conteúdo.
    return Scaffold(
      backgroundColor: AppColors.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                children: [
                  const SizedBox(
                    height: 300,
                    width: double.infinity,
                    child: DecorativeBanner(child: _BannerContent()),
                  ),
                  Transform.translate(
                    offset: const Offset(0, -28),
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(28),
                          topRight: Radius.circular(28),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
                        child: _buildFormulario(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFormulario() {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Acesse sua conta', style: AppTextStyles.tituloLogin()),
          const SizedBox(height: 4),
          Text(
            'Entre com suas credenciais para continuar',
            style: AppTextStyles.subtituloLogin(),
          ),
          const SizedBox(height: 32),

          Text('E-mail', style: AppTextStyles.label()),
          const SizedBox(height: 8),
          AppTextField(
            controller: _emailController,
            hint: 'seu@email.com',
            keyboardType: TextInputType.emailAddress,
            validator: _validarEmail,
          ),
          const SizedBox(height: 18),

          Text('Senha', style: AppTextStyles.label()),
          const SizedBox(height: 8),
          AppTextField(
            controller: _senhaController,
            hint: '••••••••',
            obscureText: !_senhaVisivel,
            textInputAction: TextInputAction.done,
            validator: _validarSenha,
            onFieldSubmitted: (_) => _entrar(),
            suffixIcon: IconButton(
              icon: Icon(
                _senhaVisivel ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: AppColors.textMuted,
                size: 20,
              ),
              onPressed: () => setState(() => _senhaVisivel = !_senhaVisivel),
            ),
          ),
          const SizedBox(height: 10),

          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: widget.onEsqueciSenha ?? _abrirEsqueciSenha,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text('Esqueci minha senha', style: AppTextStyles.linkSenha()),
            ),
          ),

          if (_mensagemSucesso != null) ...[
            const SizedBox(height: 16),
            _buildAlertaSucesso(_mensagemSucesso!),
          ],

          if (_mensagemErro != null) ...[
            const SizedBox(height: 16),
            _buildAlertaErro(_mensagemErro!),
          ],

          const SizedBox(height: 24),
          AppButton(
            label: 'ENTRAR',
            loading: _carregando,
            onPressed: _entrar,
          ),

          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Não tem conta? ', style: AppTextStyles.subtituloLogin(size: 13)),
              GestureDetector(
                onTap: widget.onCriarConta ?? _abrirCadastro,
                child: Text('Cadastre-se', style: AppTextStyles.linkSenha(size: 13)),
              ),
            ],
          ),

          const SizedBox(height: 28),
          Center(
            child: Text(
              'Maxi Massas Itápolis • App do Cliente',
              style: AppTextStyles.rodape(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertaSucesso(String mensagem) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Text(
        mensagem,
        textAlign: TextAlign.center,
        style: AppTextStyles.erro.copyWith(color: AppColors.success),
      ),
    );
  }

  Widget _buildAlertaErro(String mensagem) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.errorBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.errorBorder),
      ),
      child: Text(mensagem, textAlign: TextAlign.center, style: AppTextStyles.erro),
    );
  }
}

class _BannerContent extends StatelessWidget {
  const _BannerContent();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/logo.png', width: 96),
            const SizedBox(height: 16),
            Text('Maxi Massas', style: AppTextStyles.tituloBanner(), textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text('Itápolis', style: AppTextStyles.subtituloBanner(size: 14), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
