import '../models/franchise_info.dart';

/// Dados fixos da franquia (endereço/horário de retirada), usados até
/// existir um endpoint de configuração da loja na API. Quando existir,
/// troque este valor por uma chamada real (ex.: `GET /api/Franquia`).
const franquiaPadrao = FranchiseInfo(
  name: 'Maxi Massas Itápolis',
  address: 'Rua Voluntários de 32, 456 — Centro, Itápolis/SP',
  hours: 'Terça a domingo, das 18h às 23h',
  phoneNumber: '(16) 99999-0000',
  tempoPreparoMinutos: 30,
  tempoEntregaMinutos: 45,
  pixKey: '16999990000',
);
