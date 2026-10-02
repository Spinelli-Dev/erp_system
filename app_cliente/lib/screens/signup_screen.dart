import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../core/app_text_styles.dart';
import '../core/validators.dart';
import '../providers/auth_provider.dart';
import '../providers/navigation_provider.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import '../widgets/decorative_banner.dart';
import '../widgets/form_error_alert.dart';
import '../widgets/password_checklist.dart';

/// Cadastro de cliente, aberto pelo "Cadastre-se" da tela de login.
///
/// Mesmo layout de celular do login — banner da marca no topo e o
/// formulário num cartão branco — para as duas telas parecerem uma só
/// jornada. Ao criar a conta o cliente já fica logado (o [AuthProvider]
/// chama o backend) e vai direto para o app, sem passar pelo login de novo.
///
/// [destino] é a aba para abrir depois, repassada pelo login quando ele
/// foi aberto por um deep link sem sessão.
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key, this.destino});

  final String? destino;

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmacaoController = TextEditingController();

  bool _senhaVisivel = false;
  bool _carregando = false;
  String? _mensagemErro;

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _telefoneController.dispose();
    _senhaController.dispose();
    _confirmacaoController.dispose();
    super.dispose();
  }

  String? _validarConfirmacao(String? valor) {
    if (valor == null || valor.isEmpty) return 'Repita a senha';
    if (valor != _senhaController.text) return 'As senhas não conferem';
    return null;
  }

  Future<void> _criarConta() async {
    setState(() => _mensagemErro = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _carregando = true);
    final erro = await context.read<AuthProvider>().cadastrar(
          name: _nomeController.text.trim(),
          email: _emailController.text.trim(),
          phone: _telefoneController.text,
          senha: _senhaController.text,
        );
    if (!mounted) return;

    if (erro != null) {
      setState(() {
        _carregando = false;
        _mensagemErro = erro;
      });
      return;
    }

    // Já logado: troca login + cadastro pelo app, sem deixar como voltar.
    Navigator.of(context).pushNamedAndRemoveUntil(widget.destino ?? AppTab.produtos.rota, (_) => false);
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
          Text('Crie sua conta', style: AppTextStyles.tituloLogin()),
          const SizedBox(height: 4),
          Text('Peça suas massas favoritas em poucos toques', style: AppTextStyles.subtituloLogin()),
          const SizedBox(height: 28),

          Text('Nome', style: AppTextStyles.label()),
          const SizedBox(height: 8),
          AppTextField(
            controller: _nomeController,
            hint: 'Seu nome completo',
            textCapitalization: TextCapitalization.words,
            validator: (v) => validarObrigatorio(v, mensagem: 'Informe seu nome'),
          ),
          const SizedBox(height: 18),

          Text('E-mail', style: AppTextStyles.label()),
          const SizedBox(height: 8),
          AppTextField(
            controller: _emailController,
            hint: 'seu@email.com',
            keyboardType: TextInputType.emailAddress,
            validator: validarEmail,
          ),
          const SizedBox(height: 18),

          Text('Telefone', style: AppTextStyles.label()),
          const SizedBox(height: 8),
          AppTextField(
            controller: _telefoneController,
            hint: '(16) 99999-9999',
            keyboardType: TextInputType.phone,
            inputFormatters: const [MascaraNumerica.telefone],
            validator: validarTelefone,
          ),
          const SizedBox(height: 18),

          Text('Senha', style: AppTextStyles.label()),
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

          Text('Confirmar senha', style: AppTextStyles.label()),
          const SizedBox(height: 8),
          AppTextField(
            controller: _confirmacaoController,
            hint: 'Repita a senha',
            obscureText: !_senhaVisivel,
            textInputAction: TextInputAction.done,
            validator: _validarConfirmacao,
            onFieldSubmitted: (_) => _criarConta(),
          ),

          if (_mensagemErro != null) ...[
            const SizedBox(height: 20),
            FormErrorAlert(mensagem: _mensagemErro!),
          ],

          const SizedBox(height: 28),
          AppButton(label: 'CRIAR CONTA', loading: _carregando, onPressed: _criarConta),

          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Já tem conta? ', style: AppTextStyles.subtituloLogin(size: 13)),
              GestureDetector(
                onTap: _carregando ? null : () => Navigator.of(context).maybePop(),
                child: Text('Entrar', style: AppTextStyles.linkSenha(size: 13)),
              ),
            ],
          ),
        ],
      ),
    );
  }
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
