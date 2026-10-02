# App Cliente — Maxi Massas Itápolis

Aplicativo de compras (Flutter) para os clientes da Maxi Massas: login,
cardápio de produtos, carrinho, finalização de pedido e confirmação —
construídos com a mesma identidade visual do site (`frontend/`) — vermelho
da marca `#9A1006`, tipografia Inter e os mesmos componentes (inputs,
botões, chips) do `frontend/css/componentes.css`.

O app é **mobile-first e mobile-only**: mesmo testado numa janela larga
(Chrome/Windows desktop), o conteúdo fica centralizado numa largura fixa de
celular — ele não vira uma versão responsiva do site administrativo.

## Fluxo

`LoginScreen` → (login válido) → `ProductsScreen` (cardápio) → tap num card
→ `ProductDetailScreen` → carrinho (`CartScreen`) → "Finalizar Pedido"
→ `CheckoutScreen` (entrega, pagamento, observações) → "Confirmar Pedido"
→ `OrderConfirmationScreen` → "Ver Meus Pedidos" → `OrderHistoryScreen`.

## Estrutura

```
app_cliente/
├── pubspec.yaml
├── assets/images/
│   ├── logo.png                  # mesma logo usada no site
│   └── imagem_temporario.png     # placeholder de foto de produto
└── lib/
    ├── main.dart                 # MultiProvider + rotas nomeadas (/login, /produtos, /carrinho)
    ├── core/
    │   ├── app_colors.dart          # paleta extraída de frontend/css/componentes.css
    │   ├── app_text_styles.dart     # tipografia (Inter) espelhando as classes *-login e de produto
    │   ├── app_assets.dart          # caminhos de assets centralizados
    │   ├── formatters.dart          # preço (R$), data/hora
    │   └── payment_instructions.dart # texto de instrução conforme forma de pagamento
    ├── models/
    │   ├── product.dart, cart_item.dart, cart_total.dart
    │   ├── delivery_type.dart, payment_method.dart   # enums com label/ícone
    │   ├── address.dart, franchise_info.dart, user_profile.dart
    │   ├── order_request.dart        # o que vai para a API no checkout
    │   └── order_confirmation.dart   # retrato completo de um pedido já confirmado
    ├── services/                  # interface + implementação mockada de cada integração
    │   ├── product_service.dart, franchise_service.dart
    │   ├── user_profile_service.dart, order_service.dart
    ├── providers/                 # state management (package:provider), tudo em memória
    │   ├── product_provider.dart, cart_provider.dart
    │   └── order_history_provider.dart  # pedidos confirmados nesta sessão
    ├── widgets/
    │   ├── decorative_banner.dart, app_text_field.dart, app_button.dart
    │   ├── category_chip.dart, segmented_toggle.dart, payment_method_card.dart
    │   ├── quantity_stepper.dart   # seletor -/N/+ (carrinho e detalhe do produto)
    │   ├── product_card.dart, product_card_skeleton.dart / skeleton_box.dart
    │   ├── product_image.dart, cart_icon_button.dart, mobile_frame.dart
    └── screens/
        ├── login_screen.dart
        ├── products_screen.dart, product_detail_screen.dart
        ├── cart_screen.dart
        ├── checkout_screen.dart          # entrega, pagamento, observações, resumo
        ├── order_confirmation_screen.dart # "Pedido Confirmado" + ações
        └── order_history_screen.dart      # "Meus Pedidos"
```

## Como rodar

1. Instale o [Flutter SDK](https://docs.flutter.dev/get-started/install) (ou
   use a instalação já feita em `C:\src\flutter`, com o `bin` no PATH do
   usuário).
2. Se as pastas de plataforma (`android/`, `ios/`, `web/`, `windows/`...)
   ainda não existirem — elas não são versionadas —, gere-as dentro de
   `app_cliente/`:
   ```bash
   cd app_cliente
   flutter create --platforms=web,windows .
   ```
   Isso preserva `pubspec.yaml` e `lib/` e só adiciona as pastas nativas.
3. Instale as dependências: `flutter pub get`
4. Rode os testes: `flutter test`
5. Rode o app no Chrome (recomendado para testar como "mobile", sem precisar
   de emulador Android): `flutter run -d chrome`. No VSCode, F5 já usa a
   configuração `app_cliente (Chrome)` definida em `.vscode/launch.json`.

## Integração com API

Cada integração externa fica isolada atrás de uma interface, injetável via
construtor, pronta para trocar o mock por dados reais sem mexer nas telas:

- **Login**: `LoginScreen` aceita um callback opcional `onLogin(email, senha)`
  que deve retornar `null` em caso de sucesso ou uma mensagem de erro.
  ```dart
  LoginScreen(
    onLogin: (email, senha) async {
      final resposta = await authService.login(email, senha);
      return resposta.sucesso ? null : resposta.mensagemErro;
    },
  )
  ```
- **Produtos**: `ProductProvider(service: ApiProductService())` — implemente
  `ApiProductService implements ProductService` mapeando a resposta com
  `Product.fromJson`.
- **Checkout**: `CheckoutScreen` recebe `orderService`, `userProfileService` e
  `franchise` opcionais. Implemente `ApiOrderService implements OrderService`
  (`POST /api/Venda` com `OrderRequest.toJson()`) e
  `ApiUserProfileService implements UserProfileService`
  (`GET /api/Cliente/perfil`), e troque a `franquiaPadrao` fixa por uma busca
  real quando existir um endpoint de configuração da loja.
- **Fotos de produto**: quando a API passar a enviar fotos reais, basta
  preencher `imageUrl` com a URL — o widget `ProductImage` já diferencia
  asset local de URL de rede e cai de volta no placeholder se o
  carregamento falhar.

Nada no app persiste em disco hoje (nem o carrinho, nem o histórico de
pedidos sobrevivem a um restart) — é tudo estado em memória via
`ChangeNotifier`, consistente em todas as telas. Se quiser manter esses
dados entre sessões antes de existir uma API de histórico, dá para
persistir `OrderHistoryProvider` com `shared_preferences`.

## Testes

`flutter test` cobre, entre outras coisas: validação do formulário de
login; carregamento do cardápio (loading → skeleton → grid) e filtro por
categoria; carrinho (quantidade mínima 1, remover com desfazer, cálculo de
totais); checkout (alternância de entrega/retirada, validação condicional
do endereço, taxa de entrega condicional, "usar endereço do perfil"); e a
tela de confirmação (seções condicionais por tipo de entrega/pagamento,
navegação dos botões de ação).
