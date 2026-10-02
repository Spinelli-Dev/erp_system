/// Endereço do cliente: tanto os salvos no perfil (com [id]) quanto o
/// endereço de entrega informado na finalização do pedido (sem [id]).
class Address {
  const Address({
    this.id,
    required this.street,
    required this.number,
    this.complement = '',
    required this.neighborhood,
    this.zipCode = '',
    this.city = '',
    this.state = '',
    this.isMain = false,
    this.saveForFuture = false,
  });

  /// Gerado pelo backend quando o endereço é salvo no perfil; `null` num
  /// endereço digitado só para um pedido.
  final String? id;

  final String street;
  final String number;
  final String complement;
  final String neighborhood;
  final String zipCode;
  final String city;

  /// UF com 2 letras (ex.: "SP").
  final String state;

  /// Se é o endereço principal do cliente (só um por perfil). É o que a
  /// finalização do pedido pré-preenche.
  final bool isMain;

  /// Se o cliente pediu para salvar este endereço para as próximas compras.
  final bool saveForFuture;

  /// "Rua das Palmeiras, 120 - Apto 21".
  String get linhaPrincipal => complement.isEmpty ? '$street, $number' : '$street, $number - $complement';

  /// "Itápolis/SP" (vazio em endereços salvos antes de a cidade existir).
  String get cidadeUf => city.isEmpty ? '' : (state.isEmpty ? city : '$city/$state');

  /// "Centro • Itápolis/SP • CEP 14900-000".
  String get linhaSecundaria =>
      [neighborhood, cidadeUf, if (zipCode.isNotEmpty) 'CEP $zipCode'].where((p) => p.isNotEmpty).join(' • ');

  Address copyWith({String? id, bool? isMain}) => Address(
        id: id ?? this.id,
        street: street,
        number: number,
        complement: complement,
        neighborhood: neighborhood,
        zipCode: zipCode,
        city: city,
        state: state,
        isMain: isMain ?? this.isMain,
        saveForFuture: saveForFuture,
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'street': street,
        'number': number,
        'complement': complement,
        'neighborhood': neighborhood,
        'zipCode': zipCode,
        'city': city,
        'state': state,
        'isMain': isMain,
        'saveForFuture': saveForFuture,
      };
}
