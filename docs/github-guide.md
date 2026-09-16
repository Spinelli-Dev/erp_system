# 🧭 Guia de Git e GitHub

Este guia contém os principais comandos e fluxos que a equipe deve utilizar durante o desenvolvimento.

---

# 📌 1. Configuração inicial (apenas 1 vez)

```
git config --global user.name "Seu Nome"
git config --global user.email "seuemail@email.com"
```

---

# 📥 2. Clonar o repositório

```
git clone <url-do-repositorio>
cd erp-system
```

---

# 🌿 3. Trabalhando com branches

## 🔄 Ir para a branch de desenvolvimento

```
git checkout develop
```

## 🔄 Atualizar o projeto

```
git pull
```

## 🌱 Criar nova branch de funcionalidade

```
git checkout -b feature/nome-da-feature
```

---

# 💾 4. Salvando alterações

## Verificar arquivos modificados

```
git status
```

## Adicionar alterações

```
git add .
```

## Criar commit

```
git commit -m "feat: descrição da funcionalidade"
```

---

# 🚀 5. Enviando para o GitHub

```
git push origin feature/nome-da-feature
```

---

# 🔀 6. Pull Request (PR)

1. Acesse o repositório no GitHub
2. Clique em "Compare & pull request"
3. Preencha o template
4. Solicite revisão

---

# 🔄 7. Atualizando sua branch com develop

```
git checkout develop
git pull
git checkout feature/nome-da-feature
git merge develop
```

---

# ⚠️ 8. Resolvendo conflitos

1. O Git indicará os arquivos com conflito
2. Edite manualmente
3. Depois:

```
git add .
git commit -m "fix: resolução de conflito"
```

---

# 🔁 9. Fluxo padrão do projeto

```
feature → develop → main
```

---

# 🚫 10. Regras importantes

* Nunca trabalhar direto na `main`
* Sempre atualizar a `develop` antes de começar
* Sempre usar Pull Request
* Escrever mensagens de commit claras

---

# 🏷️ 11. Padrão de commits

```
feat: nova funcionalidade
fix: correção de erro
docs: documentação
refactor: melhoria interna
```

---

# 🧹 12. Comandos úteis

## Ver histórico

```
git log
```

## Ver branches

```
git branch
```

## Deletar branch local

```
git branch -d nome-da-branch
```

---

# 🚀 13. Boas práticas

* Fazer commits pequenos e frequentes
* Nomear branches de forma clara
* Revisar código antes de subir
* Testar antes de abrir PR

---

# 📌 RESUMO

1. Atualiza `develop`
2. Cria `feature/...`
3. Desenvolve
4. Commit
5. Push
6. Pull Request

---

Esse fluxo garante organização, controle de versão e colaboração eficiente.
