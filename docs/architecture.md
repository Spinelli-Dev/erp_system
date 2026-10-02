# 🏗️ Arquitetura do Sistema ERP Maxi Massas

## 📌 Visão Geral

O sistema tem três partes, todas apoiadas no mesmo banco SQL Server:

- **Painel web** (gestores e operadores): ASP.NET Core 8 Razor Pages, renderizado no servidor.
- **API** (`/api/...`): mesmo projeto ASP.NET Core; atende o app do cliente e integrações.
- **App do cliente** (Flutter): cardápio, carrinho, pedidos, histórico e conta. Layout só para celular.

Painel e API ficam no projeto `backend/` e compartilham os mesmos serviços de regra de negócio
(`Services/`), então uma regra (estoque, taxa de entrega, senha...) vale igual para os dois.

---

## 🔄 Fluxo da Aplicação

**Painel:** o navegador envia formulários (POST com antiforgery) para as páginas Razor → a página chama
os serviços → os serviços usam o EF Core (`AppDbContext`) → o servidor devolve o HTML pronto.

**App:** o Flutter chama `/api/app/...` em JSON → o `AppController` usa os mesmos serviços →
resposta no envelope `ApiResponse` (`success`, `message`, `data`, `errors`).

Pedidos feitos no app viram `Venda` com `Origem = "App"` e aparecem no painel.

---

## 🔐 Autenticação

- **Painel:** login com usuário e senha (BCrypt) → cookie de sessão "Painel" (HttpOnly, SameSite=Strict,
  8 h deslizantes). Perfis: Administrador (gestor) e Operador. Usuário desativado perde a sessão.
- **API interna:** Basic Auth com usuário do painel.
- **App:** Basic Auth com e-mail e senha do **cliente** (esquema `ClienteAuth`); o cliente só acessa os
  próprios dados.
- **Esqueci minha senha:** painel por link no e-mail (1 h, uso único); app por código de 6 dígitos
  (15 min, até 5 tentativas). Só o hash SHA-256 fica no banco.

---

## 📂 Estrutura do Projeto

- `/backend` → API, painel Razor, regras de negócio e migrações do banco
- `/app_cliente` → app Flutter do cliente
- `/database` → scripts SQL de apoio
- `/docs` → documentação

---

## ⚙️ Considerações Técnicas

- Banco evolui por migrações do EF Core (`backend/Migrations`).
- Backup automático diário do SQL Server (`BackupService`, configurado em `appsettings.json` → `Backup`).
- E-mail via MailKit; em desenvolvimento (`EmailSettings:MockMode = true`) os e-mails são gravados em
  `backend/EmailsTeste` em vez de enviados.
- Taxa de entrega é definida pelos gestores no painel (banco), nunca fixa no código.
