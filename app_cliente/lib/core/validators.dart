import 'package:flutter/services.dart';

/// Validações e máscaras de formulário compartilhadas pelas telas (login,
/// edição de perfil, endereços, checkout). Os validadores seguem o
/// contrato de `TextFormField.validator`: `null` quando o valor é válido.

String _digitos(String? valor) => (valor ?? '').replaceAll(RegExp(r'\D'), '');

String? validarObrigatorio(String? valor, {String mensagem = 'Campo obrigatório'}) =>
    (valor ?? '').trim().isEmpty ? mensagem : null;

String? validarEmail(String? valor) {
  final email = valor?.trim() ?? '';
  if (email.isEmpty) return 'Informe seu e-mail';
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) return 'Informe um e-mail válido';
  return null;
}

/// Celular com DDD: (XX) XXXXX-XXXX.
String? validarTelefone(String? valor) {
  final digitos = _digitos(valor);
  if (digitos.isEmpty) return 'Informe seu telefone';
  if (digitos.length != 11) return 'Use o formato (XX) XXXXX-XXXX';
  return null;
}

String? validarCep(String? valor, {bool obrigatorio = true}) {
  final digitos = _digitos(valor);
  if (digitos.isEmpty) return obrigatorio ? 'Informe o CEP' : null;
  if (digitos.length != 8) return 'CEP inválido';
  return null;
}

/// Máscara que aplica um padrão onde `#` é um dígito: ao digitar, só os
/// números são aproveitados e os separadores entram sozinhos.
class MascaraNumerica extends TextInputFormatter {
  const MascaraNumerica(this.padrao);

  /// Ex.: `(##) #####-####`.
  final String padrao;

  static const telefone = MascaraNumerica('(##) #####-####');
  static const cep = MascaraNumerica('#####-###');

  /// Código de 6 dígitos do "Esqueci minha senha".
  static const codigo = MascaraNumerica('######');

  int get _maxDigitos => '#'.allMatches(padrao).length;

  String aplicar(String texto) {
    final digitos = _digitos(texto);
    final limitados = digitos.length > _maxDigitos ? digitos.substring(0, _maxDigitos) : digitos;
    final saida = StringBuffer();
    var i = 0;
    for (final caractere in padrao.split('')) {
      if (i >= limitados.length) break;
      if (caractere == '#') {
        saida.write(limitados[i++]);
      } else {
        saida.write(caractere);
      }
    }
    return saida.toString();
  }

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final formatado = aplicar(newValue.text);
    // Cursor sempre no fim: o campo é curto e só recebe dígitos.
    return TextEditingValue(text: formatado, selection: TextSelection.collapsed(offset: formatado.length));
  }
}

/// Uma exigência da senha de cadastro. A mesma lista alimenta o checklist
/// mostrado embaixo do campo ([regrasSenha]) e a validação do formulário
/// ([validarSenhaNova]) — e espelha o backend (`AppClienteValidator`).
class RegraSenha {
  const RegraSenha(this.descricao, this._atendida);

  final String descricao;
  final bool Function(String senha) _atendida;

  bool atendidaPor(String senha) => _atendida(senha);
}

const tamanhoMinimoSenha = 8;

final _letra = RegExp(r'\p{L}', unicode: true);
final _numero = RegExp(r'\d');

final List<RegraSenha> regrasSenha = [
  RegraSenha('Pelo menos $tamanhoMinimoSenha caracteres', (s) => s.length >= tamanhoMinimoSenha),
  RegraSenha('Pelo menos uma letra', _letra.hasMatch),
  RegraSenha('Pelo menos um número', _numero.hasMatch),
];

/// Senha de uma conta nova. O detalhe do que falta fica no checklist, que
/// já está visível embaixo do campo; aqui só a chamada para conferir.
String? validarSenhaNova(String? valor) {
  final senha = valor ?? '';
  if (senha.isEmpty) return 'Crie uma senha';
  if (!regrasSenha.every((regra) => regra.atendidaPor(senha))) return 'A senha ainda não atende aos requisitos';
  return null;
}

const _ufs = {
  'AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO', 'MA', 'MT', 'MS', 'MG', 'PA',
  'PB', 'PR', 'PE', 'PI', 'RJ', 'RN', 'RS', 'RO', 'RR', 'SC', 'SP', 'SE', 'TO',
};

/// Sigla de estado brasileiro (ex.: "SP").
String? validarUf(String? valor) {
  final uf = (valor ?? '').trim().toUpperCase();
  if (uf.isEmpty) return 'Informe a UF';
  if (!_ufs.contains(uf)) return 'UF inválida';
  return null;
}
