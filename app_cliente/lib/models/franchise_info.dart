/// Dados fixos da franquia — usados na opção "Retirar no Local" e na
/// tela de confirmação do pedido (contato, instruções de Pix etc.).
class FranchiseInfo {
  const FranchiseInfo({
    required this.name,
    required this.address,
    required this.hours,
    required this.phoneNumber,
    required this.tempoPreparoMinutos,
    required this.tempoEntregaMinutos,
    required this.pixKey,
  });

  final String name;
  final String address;
  final String hours;
  final String phoneNumber;

  /// Tempo estimado de preparo para quem escolhe retirar no local, em
  /// minutos — usado na mensagem "Sua compra estará pronta em X minutos".
  final int tempoPreparoMinutos;

  /// Tempo estimado total (preparo + trajeto) para quem escolhe receber
  /// no endereço, em minutos.
  final int tempoEntregaMinutos;

  /// Chave Pix da franquia, mostrada nas instruções de pagamento quando o
  /// cliente escolhe pagar por Pix.
  final String pixKey;
}
