import '../models/delivery_fee_rule.dart';
import 'api_client.dart';

/// Onde buscar a regra da taxa de entrega (ver [DeliveryFeeRule]).
abstract class DeliveryFeeService {
  Future<DeliveryFeeRule> buscarRegra();
}

/// `GET /api/app/entrega` — público, sem login. O valor cobrado de fato é
/// recalculado pelo servidor no pedido; aqui é só para mostrar antes.
class ApiDeliveryFeeService implements DeliveryFeeService {
  ApiDeliveryFeeService(this._api);

  final ApiClient _api;

  @override
  Future<DeliveryFeeRule> buscarRegra() async =>
      DeliveryFeeRule.fromJson(await _api.get('/app/entrega') as Map<String, dynamic>);
}
