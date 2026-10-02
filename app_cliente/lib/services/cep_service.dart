import 'api_client.dart';

/// Endereço encontrado pelo CEP. [street] e [neighborhood] podem vir
/// vazios em CEPs gerais de cidade (aí o cliente digita).
class CepResult {
  const CepResult({
    required this.zipCode,
    required this.street,
    required this.neighborhood,
    required this.city,
    required this.state,
  });

  final String zipCode;
  final String street;
  final String neighborhood;
  final String city;
  final String state;
}

/// Consulta de CEP para preencher o formulário de endereço.
abstract class CepService {
  /// `null` se o CEP não existe. Lança [ApiException] sem conexão.
  Future<CepResult?> buscar(String cep);
}

/// `GET /api/app/cep/{cep}` — o backend consulta o ViaCEP.
class ApiCepService implements CepService {
  ApiCepService(this._api);

  final ApiClient _api;

  @override
  Future<CepResult?> buscar(String cep) async {
    final digitos = cep.replaceAll(RegExp(r'\D'), '');
    try {
      final json = await _api.get('/app/cep/$digitos') as Map<String, dynamic>;
      return CepResult(
        zipCode: json['cep'] as String? ?? cep,
        street: json['logradouro'] as String? ?? '',
        neighborhood: json['bairro'] as String? ?? '',
        city: json['cidade'] as String? ?? '',
        state: json['estado'] as String? ?? '',
      );
    } on ApiException catch (erro) {
      if (erro.statusCode == 404) return null;
      rethrow;
    }
  }
}
