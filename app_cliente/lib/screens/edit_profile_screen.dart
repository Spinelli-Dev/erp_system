import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../core/app_text_styles.dart';
import '../core/validators.dart';
import '../providers/auth_provider.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import '../widgets/form_error_alert.dart';

/// Edição de nome, e-mail e telefone do cliente, aberta pelo ✏️ da aba
/// Perfil. Salva pelo [AuthProvider] (que chama o backend) e, se der
/// certo, fecha devolvendo `true` — o Perfil mostra a confirmação.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _usuario = context.read<AuthProvider>().usuario;
  late final _nomeController = TextEditingController(text: _usuario?.name);
  late final _emailController = TextEditingController(text: _usuario?.email);
  late final _telefoneController = TextEditingController(text: MascaraNumerica.telefone.aplicar(_usuario?.phone ?? ''));

  bool _salvando = false;
  String? _erro;

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _telefoneController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    setState(() => _erro = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _salvando = true);
    final erro = await context.read<AuthProvider>().atualizarDados(
          name: _nomeController.text.trim(),
          email: _emailController.text.trim(),
          phone: _telefoneController.text,
        );
    if (!mounted) return;

    if (erro == null) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _salvando = false;
        _erro = erro;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text('Editar Dados', style: AppTextStyles.appBarTitulo),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            children: [
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
                textInputAction: TextInputAction.done,
                inputFormatters: const [MascaraNumerica.telefone],
                validator: validarTelefone,
                onFieldSubmitted: (_) => _salvar(),
              ),
              if (_erro != null) ...[
                const SizedBox(height: 20),
                FormErrorAlert(mensagem: _erro!),
              ],
              const SizedBox(height: 28),
              AppButton(label: 'SALVAR ALTERAÇÕES', loading: _salvando, onPressed: _salvar),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: _salvando ? null : () => Navigator.of(context).pop(false),
                  child: Text('Cancelar', style: AppTextStyles.linkSenha(size: 14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
