# 🍝 ERP Maxi Massas

![Status](https://img.shields.io/badge/status-em%20desenvolvimento-yellow)
![Version](https://img.shields.io/badge/version-0.1-blue)
![License](https://img.shields.io/badge/license-MIT-green)

---

## 📌 Sobre o Projeto

O **ERP Maxi Massas** é um sistema de gestão empresarial desenvolvido para auxiliar no controle completo de operações comerciais, incluindo clientes, vendas, estoque e financeiro.

O projeto está sendo desenvolvido com foco em organização, boas práticas de desenvolvimento e colaboração em equipe.

---

## 🎯 Objetivo

Fornecer uma solução integrada para:

- Controle de Clientes
- Controle de Vendas
- Controle Financeiro
- Controle de Estoque

---

## ⚙️ Funcionalidades

### 👤 Usuários
- Cadastro de usuários
- Login e autenticação

### 🧾 Clientes
- Cadastro de clientes
- Alteração de dados de clientes

### 📦 Produtos e Estoque
- Cadastro de produtos
- Alteração de dados do produto
- Controle de estoque
- Reposição de estoque

### 💰 Vendas
- Cadastro de vendas

### 🚚 Entregas
- Controle de entregas

---

## 🛠️ Tecnologias Utilizadas

### Painel web (gestores e operadores)
- ASP.NET Core 8 Razor Pages (renderizado no servidor), Bootstrap 5

### Backend / API
- ASP.NET Core 8 (C#), Entity Framework Core

### App do cliente
- Flutter (Android, iOS e web), layout exclusivo para celular

### Banco de Dados
- SQL Server

---

## 🏗️ Estrutura do Projeto

```
erp_system/
│
├── backend/                 → API + painel web (um único projeto ASP.NET Core)
│   ├── Controllers/         → API REST (/api/... e /api/app/... para o app)
│   ├── Pages/               → painel web em Razor Pages
│   ├── Services/            → regras de negócio
│   ├── Models/ DTOs/ Data/  → entidades, contratos e EF Core (AppDbContext)
│   ├── Migrations/          → evolução do banco (EF Core)
│   └── wwwroot/             → CSS, JS e imagens do painel
│
├── app_cliente/             → app Flutter do cliente (cardápio, pedidos, conta)
│
├── database/                → scripts SQL de apoio
├── docs/                    → documentação
├── .gitignore
└── README.md
```

---

## 🚀 Como Executar o Projeto

**Backend + painel** (requer .NET 8 e SQL Server local com o banco `MaxiMassasDB`):

```bash
cd backend
dotnet run --launch-profile https
# painel: https://localhost:5001   ·   Swagger: https://localhost:5001/swagger
```

Na primeira execução o backend cria o banco e o usuário `admin`. Para carregar o cardápio inicial (produtos, estoque e taxa de entrega), rode uma vez, a partir da raiz do projeto:

```bash
sqlcmd -S localhost -E -I -d MaxiMassasDB -f 65001 -i database/seed.sql
```

O script pode ser rodado de novo sem duplicar dados. Clientes, usuários e vendas não vão junto: cada máquina tem o seu próprio banco.

**App do cliente** (requer Flutter):

```bash
cd app_cliente
flutter run -d chrome --dart-define=API_BASE_URL=https://localhost:5001/api
```

Sem `API_BASE_URL`, o app roda com dados de demonstração.

---

## 👥 Equipe

- **Brenda** – UX/UI
- **Flávio** – Frontend
- **João** – Backend
- **Reinaldo** – Banco de Dados

---

## 📊 Status do Projeto

🚧 Em desenvolvimento

---

## 💡 Diferenciais

- Arquitetura organizada
- Separação clara entre painel web, API, app do cliente e banco de dados
- Uso de boas práticas com Git e GitHub
- Trabalho colaborativo em equipe

---

## 📄 Licença

Este projeto é de uso privado e exclusivo da equipe ERP Maxxi Massas.

Todos os direitos estão reservados.

Não é permitido copiar, modificar, distribuir ou utilizar este software sem autorização explícita dos autores.

---

## 📌 Observações Finais

Este projeto está em constante evolução e novas funcionalidades serão adicionadas conforme o desenvolvimento avança.

---

