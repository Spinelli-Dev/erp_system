import 'dart:convert';

import 'package:http/http.dart' as http;

/// Erro devolvido pela API (ou de rede), com a mensagem pronta para a tela.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;

  /// `null` quando nem chegou resposta (servidor fora do ar, sem internet).
  final int? statusCode;

  bool get naoAutorizado => statusCode == 401;

  @override
  String toString() => message;
}

/// Cliente HTTP dos endpoints `/api/app` do backend MaxiMassas.
///
/// A API não emite token: o login do cliente é Basic Auth (e-mail e senha),
/// reenviado em toda requisição — por isso as credenciais ficam guardadas
/// aqui depois de [definirCredenciais]. Toda resposta vem no envelope
/// `{ success, message, data, errors }`; os métodos já devolvem só `data`.
class ApiClient {
  ApiClient({required String baseUrl, http.Client? httpClient})
      : _baseUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl,
        _http = httpClient ?? http.Client();

  final String _baseUrl;
  final http.Client _http;
  String? _email;
  String? _senha;

  static const _timeout = Duration(seconds: 15);

  void definirCredenciais(String email, String senha) {
    _email = email;
    _senha = senha;
  }

  /// Depois que o cliente troca o e-mail no perfil, o login passa a ser o
  /// novo — a senha continua a mesma.
  void atualizarEmail(String email) {
    if (_senha != null) _email = email;
  }

  void limparCredenciais() {
    _email = null;
    _senha = null;
  }

  Future<dynamic> get(String caminho) => _enviar(() => _http.get(_uri(caminho), headers: _headers()));

  Future<dynamic> post(String caminho, Map<String, dynamic> corpo) =>
      _enviar(() => _http.post(_uri(caminho), headers: _headers(), body: jsonEncode(corpo)));

  Future<dynamic> put(String caminho, [Map<String, dynamic>? corpo]) => _enviar(
      () => _http.put(_uri(caminho), headers: _headers(), body: corpo == null ? null : jsonEncode(corpo)));

  Future<dynamic> delete(String caminho) => _enviar(() => _http.delete(_uri(caminho), headers: _headers()));

  Uri _uri(String caminho) => Uri.parse('$_baseUrl$caminho');

  Map<String, String> _headers() => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (_email != null && _senha != null)
          'Authorization': 'Basic ${base64Encode(utf8.encode('$_email:$_senha'))}',
      };

  Future<dynamic> _enviar(Future<http.Response> Function() requisicao) async {
    final http.Response resposta;
    try {
      resposta = await requisicao().timeout(_timeout);
    } catch (_) {
      throw const ApiException('Não foi possível conectar ao servidor. Verifique sua conexão.');
    }

    if (resposta.statusCode == 401) {
      throw const ApiException('E-mail ou senha incorretos.', statusCode: 401);
    }

    final corpo = _decodificar(resposta);
    final sucesso = resposta.statusCode >= 200 && resposta.statusCode < 300;
    if (sucesso && corpo is Map<String, dynamic> && corpo['success'] != false) return corpo['data'];

    throw ApiException(_mensagemDeErro(corpo, resposta.statusCode), statusCode: resposta.statusCode);
  }

  dynamic _decodificar(http.Response resposta) {
    if (resposta.body.isEmpty) return null;
    try {
      return jsonDecode(utf8.decode(resposta.bodyBytes));
    } on FormatException {
      return null;
    }
  }

  /// Envelope da API (`message`) ou erros de validação do ASP.NET
  /// (`errors: { Campo: ["mensagem"] }`).
  String _mensagemDeErro(dynamic corpo, int status) {
    if (corpo is Map<String, dynamic>) {
      final erros = corpo['errors'];
      if (erros is Map && erros.isNotEmpty) {
        final primeiro = erros.values.first;
        if (primeiro is List && primeiro.isNotEmpty) return primeiro.first.toString();
      }
      final mensagem = corpo['message'];
      if (mensagem is String && mensagem.isNotEmpty) return mensagem;
    }
    return 'Erro $status ao falar com o servidor. Tente novamente.';
  }
}
