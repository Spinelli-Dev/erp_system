import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Abre uma conversa no WhatsApp com a loja, já com uma mensagem
/// sugerida. Usa o link universal `wa.me`, que funciona no celular (abre
/// o app) e no navegador (abre o WhatsApp Web).
class WhatsAppService {
  WhatsAppService._();

  /// Troca a abertura real do link nos testes (o plugin do url_launcher
  /// não existe no ambiente de teste).
  @visibleForTesting
  static Future<bool> Function(Uri uri) abrirLink =
      (uri) => launchUrl(uri, mode: LaunchMode.externalApplication);

  /// `(16) 99999-0000` -> `https://wa.me/5516999990000?text=...`.
  /// Números sem o código do país recebem o do Brasil (55).
  static Uri montarLink(String telefone, String mensagem) {
    var digitos = telefone.replaceAll(RegExp(r'\D'), '');
    if (digitos.length <= 11) digitos = '55$digitos';
    return Uri.https('wa.me', '/$digitos', {'text': mensagem});
  }

  /// Retorna `false` se não deu para abrir (sem WhatsApp nem navegador,
  /// link bloqueado etc.) — quem chama avisa o usuário.
  static Future<bool> abrirConversa({required String telefone, required String mensagem}) async {
    try {
      return await abrirLink(montarLink(telefone, mensagem));
    } catch (erro) {
      debugPrint('Falha ao abrir o WhatsApp: $erro');
      return false;
    }
  }
}
