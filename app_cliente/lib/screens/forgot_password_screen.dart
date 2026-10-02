import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../core/app_text_styles.dart';
import '../core/validators.dart';
import '../providers/auth_provider.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import '../widgets/decorative_banner.dart';
import '../widgets/form_error_alert.dart';
import '../widgets/password_checklist.dart';

/// "Esqueci minha senha", aberto pelo link da tela de login.
///
/// Duas etapas na mesma tela, com o layout de celular do cadastro:
/// 1. o cliente informa o e-mail e o backend manda um código de 6 dígitos
///    (válido por 15 minutos);
/// 2. ele digita o código e cria a nova senha (com o mesmo checklist do
///    cadastro). O servidor aceita no máximo 5 tentativas por código.
///
/// Ao terminar, volta para o login devolvendo o e-mail (`Navigator.pop`),
/// para o login já vir preenchido e mostrar que a senha mudou.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.emailInicial = ''});

  final String emailInicial;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  /// Mesmo intervalo do backend entre dois e-mails para a mesma conta.
  static const intervaloReenvio = 60;

  final _formEmailKey = GlobalKey<FormState>();
  final _formSenhaKey = GlobalKey<FormState>();
  late final _emailController = TextEditingController(text: widget.emailInicial);
  final _codigoController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmacaoController = TextEditingController();

  bool _codigoEnviado = false;
  bool _senhaVisivel = false;
  bool _carregando = false;
  String? _mensagemErro;

  Timer? _timer;
  int _segundosParaReenviar = 0;

  @override
  void dispose() {
    _timer?.cancel();
    _emailController.dispose();
    _codigoController.dispose();
    _senhaController.dispose();
    _confirmacaoController.dispose();
    super.dispose();
  }

  String get _email => _emailController.text.trim();

  Future<void> _enviarCodigo() async {
    setState(() => _mensagemErro = null);
    if (!_codigoEnviado && !(_formEmailKey.currentState?.validate() ?? false)) return;

    setState(() => _carregando = true);
    final erro = await context.read<AuthProvider>().solicitarCodigoSenha(_email);
    if (!mounted) return;

    setState(() {
      _carregando = false;
      _mensagemErro = erro;
      if (erro == null) {
        _codigoEnviado = true;
        _codigoController.clear();
        _iniciarContagem();
      }
    });
  }

  void _iniciarContagem() {
    _timer?.cancel();
    _segundosParaReenviar = intervaloReenvio;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      setState(() => _segundosParaReenviar--);
      if (_segundosParaReenviar <= 0) timer.cancel();
    });
  }

  void _trocarEmail() {
    _timer?.cancel();
    setState(() {
      _codigoEnviado = false;
      _mensagemErro = null;
      _segundosParaReenviar = 0;
    });
  }

  String? _validarCodigo(String? valor) {
    final codigo = valor ?? '';
    if (codigo.isEmpty) return 'Informe o código recebido';
    if (codigo.length != 6) return 'O código tem 6 dígitos';
    return null;
  }

  String? _validarConfirmacao(String? valor) {
    if (valor == null || valor.isEmpty) return 'Repita a nova senha';
    if (valor != _senhaController.text) return 'As senhas não conferem';
    return null;
  }

  Future<void> _salvarSenha() async {
    setState(() => _mensagemErro = null);
    if (!(_formSenhaKey.currentState?.validate() ?? false)) return;

    setState(() => _carregando = true);
    final erro = await context.read<AuthProvider>().redefinirSenha(
          email: _email,
          codigo: _codigoController.text,
          novaSenha: _senhaController.text,
        );
    if (!mounted) return;

    if (erro != null) {
      setState(() {
        _carregando = false;
        _mensagemErro = erro;
      });
      return;
    }
    Navigator.of(context).pop(_email);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                children: [
                  SizedBox(
                    height: 210,
                    width: double.infinity,
                    child: DecorativeBanner(
                      child: Stack(
                        children: [
                          const _BannerContent(),
                          SafeArea(
                            child: IconButton(
                              tooltip: 'Voltar',
                              icon: const Icon(Icons.arrow_back, color: Colors.white),
                              onPressed: _carregando ? null : () => Navigator.of(context).maybePop(),
                            ),
                          ),
                        ],
                      ),
                    ),
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
                        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                        child: _codigoEnviado ? _buildEtapaSenha() : _buildEtapaEmail(),
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

  Widget _buildEtapaEmail() {
    return Form(
      key: _formEmailKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Esqueci minha senha', style: AppTextStyles.tituloLogin()),
          const SizedBox(height: 4),
          Text(
            'Informe o e-mail da sua conta. Vamos enviar um código para você criar uma nova senha.',
            style: AppTextStyles.subtituloLogin(),
          ),
          const SizedBox(height: 28),

          Text('E-mail', style: AppTextStyles.label()),
          const SizedBox(height: 8),
          AppTextField(
            controller: _emailController,
            hint: 'seu@email.com',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            validator: validarEmail,
            onFieldSubmitted: (_) => _enviarCodigo(),
          ),

          if (_mensagemErro != null) ...[
            const SizedBox(height: 20),
            FormErrorAlert(mensagem: _mensagemErro!),
          ],

          const SizedBox(height: 28),
          AppButton(label: 'ENVIAR CÓDIGO', loading: _carregando, onPressed: _enviarCodigo),
        ],
      ),
    );
  }

  Widget _buildEtapaSenha() {
    final podeReenviar = _segundosParaReenviar <= 0 && !_carregando;
    return Form(
      key: _formSenhaKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Criar nova senha', style: AppTextStyles.tituloLogin()),
          const SizedBox(height: 4),
          Text.rich(
            TextSpan(
              style: AppTextStyles.subtituloLogin(),
              children: [
                const TextSpan(text: 'Se houver uma conta com '),
                TextSpan(text: _email, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textLabel)),
                const TextSpan(
                    text: ', enviamos um código de 6 dígitos. Ele vale por 15 minutos — confira também o spam.'),
              ],
            ),
          ),
          const SizedBox(height: 28),

          Text('Código', style: AppTextStyles.label()),
          const SizedBox(height: 8),
          AppTextField(
            controller: _codigoController,
            hint: '000000',
            keyboardType: TextInputType.number,
            inputFormatters: const [MascaraNumerica.codigo],
            validator: _validarCodigo,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton(
                onPressed: podeReenviar ? _enviarCodigo : null,
                style: _estiloLink,
                child: Text(
                  podeReenviar ? 'Reenviar código' : 'Reenviar em ${_segundosParaReenviar}s',
                  style: podeReenviar ? AppTextStyles.linkSenha() : AppTextStyles.subtituloLogin(size: 13),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _carregando ? null : _trocarEmail,
                style: _estiloLink,
                child: Text('Trocar e-mail', style: AppTextStyles.linkSenha()),
              ),
            ],
          ),
          const SizedBox(height: 18),

          Text('Nova senha', style: AppTextStyles.label()),
          const SizedBox(height: 8),
          AppTextField(
            controller: _senhaController,
            hint: '••••••••',
            obscureText: !_senhaVisivel,
            validator: validarSenhaNova,
            suffixIcon: IconButton(
              tooltip: _senhaVisivel ? 'Ocultar senha' : 'Mostrar senha',
              icon: Icon(
                _senhaVisivel ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: AppColors.textMuted,
                size: 20,
              ),
              onPressed: () => setState(() => _senhaVisivel = !_senhaVisivel),
            ),
          ),
          const SizedBox(height: 4),
          PasswordChecklist(controller: _senhaController),
          const SizedBox(height: 18),

          Text('Confirmar nova senha', style: AppTextStyles.label()),
          const SizedBox(height: 8),
          AppTextField(
            controller: _confirmacaoController,
            hint: 'Repita a nova senha',
            obscureText: !_senhaVisivel,
            textInputAction: TextInputAction.done,
            validator: _validarConfirmacao,
            onFieldSubmitted: (_) => _salvarSenha(),
          ),

          if (_mensagemErro != null) ...[
            const SizedBox(height: 20),
            FormErrorAlert(mensagem: _mensagemErro!),
          ],

          const SizedBox(height: 28),
          AppButton(label: 'SALVAR NOVA SENHA', loading: _carregando, onPressed: _salvarSenha),
        ],
      ),
    );
  }

  static final _estiloLink = TextButton.styleFrom(
    padding: EdgeInsets.zero,
    minimumSize: const Size(0, 32),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  );
}

class _BannerContent extends StatelessWidget {
  const _BannerContent();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/images/logo.png', width: 72),
          const SizedBox(height: 10),
          Text('Maxi Massas', style: AppTextStyles.tituloBanner(size: 22), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
