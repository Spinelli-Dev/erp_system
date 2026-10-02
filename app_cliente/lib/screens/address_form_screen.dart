import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../core/app_text_styles.dart';
import '../models/address.dart';
import '../providers/auth_provider.dart';
import '../widgets/app_button.dart';
import '../widgets/address_fields.dart';
import '../widgets/form_error_alert.dart';

/// Cadastro ou edição de um endereço salvo, aberto pela seção "Endereços
/// Salvos" do Perfil. Sem [endereco], cria um novo; com ele, edita (campos
/// pré-preenchidos). Fecha devolvendo `true` depois de salvar.
class AddressFormScreen extends StatefulWidget {
  const AddressFormScreen({super.key, this.endereco});

  final Address? endereco;

  @override
  State<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends State<AddressFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _campos = AddressFieldsController();

  @override
  void initState() {
    super.initState();
    final endereco = widget.endereco;
    if (endereco != null) _campos.preencher(endereco);
  }

  /// O primeiro endereço sempre vira principal, e o principal atual não
  /// pode ser desmarcado aqui (só trocado, marcando outro) — nos dois
  /// casos a opção aparece marcada e travada.
  late final bool _principalObrigatorio = (widget.endereco?.isMain ?? false) ||
      (widget.endereco == null && (context.read<AuthProvider>().usuario?.addresses.isEmpty ?? true));
  late bool _principal = _principalObrigatorio;

  bool _salvando = false;
  String? _erro;

  bool get _editando => widget.endereco != null;

  @override
  void dispose() {
    _campos.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    setState(() => _erro = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _salvando = true);
    final erro = await context
        .read<AuthProvider>()
        .salvarEndereco(_campos.montar(id: widget.endereco?.id, isMain: _principal));
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
        title: Text(_editando ? 'Editar Endereço' : 'Novo Endereço', style: AppTextStyles.appBarTitulo),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            children: [
              AddressFields(controller: _campos),
              const SizedBox(height: 12),
              _buildOpcaoPrincipal(),
              if (_erro != null) ...[
                const SizedBox(height: 16),
                FormErrorAlert(mensagem: _erro!),
              ],
              const SizedBox(height: 24),
              AppButton(label: 'SALVAR ENDEREÇO', loading: _salvando, onPressed: _salvar),
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

  Widget _buildOpcaoPrincipal() {
    final alterar = _principalObrigatorio ? null : (bool? v) => setState(() => _principal = v ?? false);

    return InkWell(
      onTap: alterar == null ? null : () => alterar(!_principal),
      borderRadius: BorderRadius.circular(8),
      child: Row(
        children: [
          Checkbox(value: _principal, activeColor: AppColors.primary, onChanged: alterar),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Marcar como principal', style: AppTextStyles.label(size: 13)),
                if (_principalObrigatorio)
                  Text(
                    _editando
                        ? 'Para trocar, marque outro endereço como principal.'
                        : 'Seu primeiro endereço será o principal.',
                    style: AppTextStyles.subtituloLogin(size: 12),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
