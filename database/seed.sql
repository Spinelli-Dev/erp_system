-- ============================================================================
-- MaxiMassas ERP — dados iniciais (catálogo e taxa de entrega)
--
-- Rodar UMA vez depois que o backend criou o banco (o primeiro `dotnet run`
-- aplica as migrations e cria o usuário admin):
--
--   sqlcmd -S localhost -E -I -d MaxiMassasDB -f 65001 -i database/seed.sql
--
-- Pode rodar de novo sem duplicar nada: cada produto só entra se ainda não
-- existir um com o mesmo nome, e a taxa de entrega só é alterada se ainda
-- estiver no padrão (zerada). Clientes, usuários e vendas não fazem parte
-- daqui — para copiar esses dados, use um backup do banco.
-- ============================================================================

SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRANSACTION;

-- Tipo: 1 = Massa, 2 = Molho, 3 = Recheio, 4 = Bebida, 5 = Outros.
-- Peso em gramas.
DECLARE @produtos TABLE (
    Nome          nvarchar(200),
    Peso          decimal(10,3),
    PrecoVenda    decimal(10,2),
    Custo         decimal(10,2),
    Tipo          int,
    Sabor         nvarchar(100),
    Estoque       int,
    AlertaMinimo  int
);

INSERT INTO @produtos VALUES
    (N'Canelone 4 Queijos', 700, 39.90, 21.90, 1, NULL,         29, 5),
    (N'Molho Branco',       240,  5.90,  3.02, 2, NULL,         16, 5),
    (N'Queijo Ralado',       40,  5.50,  2.79, 5, NULL,         14, 5),
    (N'Pizza',              750, 39.90, 27.90, 1, N'Calabresa',  0, 5);

-- Produtos
INSERT INTO Produtos (Nome, Peso, PrecoVenda, Custo, Tipo, Observacao, Sabor)
SELECT p.Nome, p.Peso, p.PrecoVenda, p.Custo, p.Tipo, NULL, p.Sabor
FROM @produtos p
WHERE NOT EXISTS (SELECT 1 FROM Produtos x WHERE x.Nome = p.Nome);

-- Estoque de cada produto (um registro por produto)
INSERT INTO Estoques (Quantidade, AlertaMinimo, ProdutoId)
SELECT p.Estoque, p.AlertaMinimo, pr.Id
FROM @produtos p
JOIN Produtos pr ON pr.Nome = p.Nome
WHERE NOT EXISTS (SELECT 1 FROM Estoques e WHERE e.ProdutoId = pr.Id);

-- Entrada do estoque inicial no histórico, para o saldo ter origem
INSERT INTO MovimentacoesEstoque (Tipo, Motivo, Quantidade, Data, EstoqueId)
SELECT 1, N'Estoque inicial', e.Quantidade, SYSDATETIME(), e.Id
FROM @produtos p
JOIN Produtos pr ON pr.Nome = p.Nome
JOIN Estoques e  ON e.ProdutoId = pr.Id
WHERE e.Quantidade > 0
  AND NOT EXISTS (SELECT 1 FROM MovimentacoesEstoque m WHERE m.EstoqueId = e.Id);

-- Taxa de entrega: R$ 5,00, grátis a partir de R$ 60,00.
-- O registro (Id 1) já é criado zerado pelas migrations.
UPDATE ConfiguracoesEntrega
SET TaxaEntrega = 5.00, PedidoMinimoEntregaGratis = 60.00, AtualizadoEm = SYSDATETIME()
WHERE Id = 1 AND TaxaEntrega = 0 AND PedidoMinimoEntregaGratis = 0;

COMMIT TRANSACTION;

SELECT pr.Nome, pr.PrecoVenda, e.Quantidade AS Estoque
FROM Produtos pr LEFT JOIN Estoques e ON e.ProdutoId = pr.Id
ORDER BY pr.Id;
