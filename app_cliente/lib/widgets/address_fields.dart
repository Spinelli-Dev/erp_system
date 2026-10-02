import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../core/app_text_styles.dart';
import '../core/validators.dart';
import '../models/address.dart';
import '../services/cep_service.dart';
import 'app_text_field.dart';

/// Campos de um endereço (CEP, rua, número, complemento, bairro, cidade e
/// UF), compartilhados pelo formulário de endereço do Perfil e pela
/// finalização do pedido. Quem usa só cria, lê e descarta o controlador.
class AddressFieldsController {
  final cep = TextEditingController();
  final rua = TextEditingController();
  final numero = TextEditingController();
  final complemento = TextEditingController();
  final bairro = TextEditingController();
  final cidade = TextEditingController();
  final estado = TextEditingController();

  List<TextEditingController> get _todos => [cep, rua, numero, complemento, bairro, cidade, estado];

  /// CEP que veio de [preencher] (endereço salvo ou em edição): já está
  /// completo, então não é consultado de novo nem sobrescreve a rua.
  String? _cepPreenchido;

  void preencher(Address endereco) {
    _cepPreenchido = endereco.zipCode.replaceAll(RegExp(r'\D'), '');
    cep.text = MascaraNumerica.cep.aplicar(endereco.zipCode);
    rua.text = endereco.street;
    numero.text = endereco.number;
    complemento.text = endereco.complement;
    bairro.text = endereco.neighborhood;
    cidade.text = endereco.city;
    estado.text = endereco.state;
  }

  Address montar({String? id, bool isMain = false, bool saveForFuture = false}) => Address(
        id: id,
        zipCode: cep.text.trim(),
        street: rua.text.trim(),
        number: numero.text.trim(),
        complement: complemento.text.trim(),
        neighborhood: bairro.text.trim(),
        city: cidade.text.trim(),
        state: estado.text.trim().toUpperCase(),
        isMain: isMain,
        saveForFuture: saveForFuture,
      );

  /// Todos os obrigatórios preenchidos e válidos — para habilitar o botão
  /// de confirmar antes mesmo de o cliente tentar enviar.
  bool get completo =>
      validarCep(cep.text) == null &&
      [rua, numero, bairro, cidade].every((c) => c.text.trim().isNotEmpty) &&
      validarUf(estado.text) == null;

  void addListener(VoidCallback ouvinte) {
    for (final c in _todos) {
      c.addListener(ouvinte);
    }
  }

  void dispose() {
    for (final c in _todos) {
      c.dispose();
    }
  }
}

/// Os campos em si. O CEP vem primeiro: ao completar os 8 dígitos, busca o
/// endereço (via [cepService] ou o registrado no `main.dart`) e preenche
/// rua, bairro, cidade e UF — o cliente só completa número e complemento.
/// Se o CEP não for encontrado (ou estiver sem internet), tudo continua
/// editável para preencher à mão.
class AddressFields extends StatefulWidget {
  const AddressFields({super.key, required this.controller, this.cepService});

  final AddressFieldsController controller;
  final CepService? cepService;

  @override
  State<AddressFields> createState() => _AddressFieldsState();
}

class _AddressFieldsState extends State<AddressFields> {
  late final CepService? _cepService = widget.cepService ?? context.read<CepService?>();

  bool _buscando = false;
  String? _avisoCep;

  /// Último CEP consultado — editar outro campo não dispara a busca de novo.
  String? _ultimoCep;

  /// Muda a cada consulta (ou CEP apagado): resposta de consulta antiga é ignorada.
  int _consulta = 0;

  AddressFieldsController get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    _c.cep.addListener(_aoMudarCep);
  }

  @override
  void dispose() {
    _c.cep.removeListener(_aoMudarCep);
    super.dispose();
  }

  static String _digitos(String texto) => texto.replaceAll(RegExp(r'\D'), '');

  void _aoMudarCep() {
    final digitos = _digitos(_c.cep.text);
    if (digitos.length == 8 && digitos == _ultimoCep) return;

    // CEP incompleto, ou o de um endereço que já veio pronto: nada a consultar
    // (e uma consulta que ainda esteja em andamento perde a validade).
    if (digitos.length != 8 || digitos == _c._cepPreenchido) {
      _ultimoCep = digitos.length == 8 ? digitos : null;
      _consulta++;
      if (_avisoCep != null || _buscando) {
        setState(() {
          _avisoCep = null;
          _buscando = false;
        });
      }
      return;
    }
    _ultimoCep = digitos;
    _buscarCep(digitos);
  }

  Future<void> _buscarCep(String digitos) async {
    final servico = _cepService;
    if (servico == null) return;

    final consulta = ++_consulta;
    setState(() {
      _buscando = true;
      _avisoCep = null;
    });

    CepResult? resultado;
    String? aviso;
    try {
      resultado = await servico.buscar(digitos);
      if (resultado == null) aviso = 'CEP não encontrado. Confira os números ou preencha o endereço abaixo.';
    } catch (_) {
      aviso = 'Não foi possível consultar o CEP agora. Preencha o endereço abaixo.';
    }

    // O cliente pode ter mudado o CEP enquanto a consulta corria.
    if (!mounted || consulta != _consulta) return;
    setState(() {
      _buscando = false;
      _avisoCep = aviso;
    });

    final r = resultado;
    if (r == null) return;
    // CEP geral de cidade vem sem rua/bairro: não apaga o que já foi digitado.
    if (r.street.isNotEmpty) _c.rua.text = r.street;
    if (r.neighborhood.isNotEmpty) _c.bairro.text = r.neighborhood;
    _c.cidade.text = r.city;
    _c.estado.text = r.state;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _rotulo('CEP'),
        AppTextField(
          controller: _c.cep,
          hint: '00000-000',
          keyboardType: TextInputType.number,
          inputFormatters: const [MascaraNumerica.cep],
          validator: validarCep,
          suffixIcon: _buscando
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  ),
                )
              : null,
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            _avisoCep ?? 'Digite o CEP para preencher o endereço automaticamente.',
            style: AppTextStyles.subtituloLogin(size: 12).copyWith(
              color: _avisoCep == null ? AppColors.textMuted : AppColors.errorText,
            ),
          ),
        ),
        const SizedBox(height: 14),
        _rotulo('Rua'),
        AppTextField(
          controller: _c.rua,
          hint: 'Nome da rua',
          textCapitalization: TextCapitalization.words,
          validator: (v) => validarObrigatorio(v, mensagem: 'Informe a rua'),
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: _campo(
                'Número',
                AppTextField(
                  controller: _c.numero,
                  hint: 'Nº',
                  keyboardType: TextInputType.number,
                  validator: (v) => validarObrigatorio(v, mensagem: 'Obrigatório'),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: _campo(
                'Complemento (opcional)',
                AppTextField(controller: _c.complemento, hint: 'Apto, bloco...'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _rotulo('Bairro'),
        AppTextField(
          controller: _c.bairro,
          hint: 'Seu bairro',
          textCapitalization: TextCapitalization.words,
          validator: (v) => validarObrigatorio(v, mensagem: 'Informe o bairro'),
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: _campo(
                'Cidade',
                AppTextField(
                  controller: _c.cidade,
                  hint: 'Sua cidade',
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => validarObrigatorio(v, mensagem: 'Informe a cidade'),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _campo(
                'UF',
                AppTextField(
                  controller: _c.estado,
                  hint: 'SP',
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp('[A-Za-z]')),
                    LengthLimitingTextInputFormatter(2),
                    _Maiusculas(),
                  ],
                  validator: validarUf,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _rotulo(String texto) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(texto, style: AppTextStyles.label()),
      );

  Widget _campo(String rotulo, Widget campo) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_rotulo(rotulo), campo],
      );
}

class _Maiusculas extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) =>
      newValue.copyWith(text: newValue.text.toUpperCase());
}
