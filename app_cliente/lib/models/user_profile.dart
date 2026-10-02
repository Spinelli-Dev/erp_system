import 'address.dart';

/// Dados do cliente logado: contato (exibido e editável no Perfil, e
/// usado na finalização do pedido) e os endereços salvos.
class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    this.addresses = const [],
  });

  final String id;
  final String name;
  final String phone;
  final String email;

  /// Endereços salvos. No máximo um tem `isMain` — quem garante isso é o
  /// serviço (ver `UserProfileService`), não este modelo.
  final List<Address> addresses;

  Address? get mainAddress {
    for (final endereco in addresses) {
      if (endereco.isMain) return endereco;
    }
    return null;
  }

  String? get mainAddressId => mainAddress?.id;

  UserProfile copyWith({String? name, String? phone, String? email, List<Address>? addresses}) => UserProfile(
        id: id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        addresses: addresses ?? this.addresses,
      );
}
