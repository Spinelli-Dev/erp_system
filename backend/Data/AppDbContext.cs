// DbContext principal — atualizado para refletir o diagrama UML.
// Todas as configurações via Fluent API para máximo controle.
using MaxiMassasAPI.Models;
using Microsoft.EntityFrameworkCore;

namespace MaxiMassasAPI.Data;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

    // ── DbSets ────────────────────────────────────────────────────────────────
    public DbSet<Usuario> Usuarios => Set<Usuario>();
    public DbSet<Cliente> Clientes => Set<Cliente>();
    public DbSet<Venda> Vendas => Set<Venda>();
    public DbSet<ItemVenda> ItensVenda => Set<ItemVenda>();
    public DbSet<Produto> Produtos => Set<Produto>();
    public DbSet<VariacaoProduto> VariacoesProduto => Set<VariacaoProduto>();
    public DbSet<HistoricoPreco> HistoricoPrecos => Set<HistoricoPreco>();
    public DbSet<Estoque> Estoques => Set<Estoque>();
    public DbSet<MovimentacaoEstoque> MovimentacoesEstoque => Set<MovimentacaoEstoque>();
    public DbSet<Pagamento> Pagamentos => Set<Pagamento>();
    public DbSet<Entrega> Entregas => Set<Entrega>();

    // RF04 — Consumo Próprio
    public DbSet<ConsumoProprio> ConsumosProprios => Set<ConsumoProprio>();

    // US16 — Tokens de redefinição de senha
    public DbSet<PasswordResetToken> PasswordResetTokens => Set<PasswordResetToken>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // ── Usuario ───────────────────────────────────────────────────────────
        modelBuilder.Entity<Usuario>(e => {
            e.HasKey(u => u.Id);
            e.Property(u => u.Nome).IsRequired().HasMaxLength(150);
            e.Property(u => u.Login).IsRequired().HasMaxLength(100);
            e.HasIndex(u => u.Login).IsUnique();
            e.Property(u => u.Senha).IsRequired().HasMaxLength(256);
        });

        // ── Cliente (UML: + Cpf, Endereco como computed) ─────────────────────
        modelBuilder.Entity<Cliente>(e => {
            e.HasKey(c => c.Id);
            e.Property(c => c.Nome).IsRequired().HasMaxLength(150);
            e.Property(c => c.Telefone).IsRequired().HasMaxLength(20);
            // CPF: opcional (nullable), max 14 chars (com máscara: 000.000.000-00)
            e.Property(c => c.Cpf).HasMaxLength(14);
            // Índice único no CPF quando preenchido (evita duplicados)
            e.HasIndex(c => c.Cpf).IsUnique().HasFilter("[Cpf] IS NOT NULL");
            e.Property(c => c.CEP).IsRequired().HasMaxLength(8);
            e.Property(c => c.Logradouro).IsRequired().HasMaxLength(200);
            e.Property(c => c.Numero).IsRequired().HasMaxLength(20);
            e.Property(c => c.Bairro).IsRequired().HasMaxLength(100);
            e.Property(c => c.Cidade).IsRequired().HasMaxLength(100);
            e.Property(c => c.Estado).IsRequired().HasMaxLength(2);
            e.Property(c => c.Complemento).HasMaxLength(100);
            e.Property(c => c.Observacao).HasMaxLength(500);
            // Endereco é computed property, não persistida no banco
            e.Ignore(c => c.Endereco);
        });

        // ── Produto ───────────────────────────────────────────────────────────
        modelBuilder.Entity<Produto>(e => {
            e.HasKey(p => p.Id);
            e.Property(p => p.Nome).IsRequired().HasMaxLength(150);
            e.Property(p => p.PrecoVenda).HasColumnType("decimal(10,2)");
            e.Property(p => p.Custo).HasColumnType("decimal(10,2)");
            e.Property(p => p.Peso).HasColumnType("decimal(10,3)");
        });

        // ── Venda (UML: + Frete, Observacao, Status; - StatusPagamento) ───────
        modelBuilder.Entity<Venda>(e => {
            e.HasKey(v => v.Id);
            e.Property(v => v.ValorTotal).HasColumnType("decimal(10,2)");
            e.Property(v => v.Desconto).HasColumnType("decimal(10,2)");
            e.Property(v => v.Frete).HasColumnType("decimal(10,2)").HasDefaultValue(0m);
            e.Property(v => v.Observacao).HasMaxLength(500);
            e.Property(v => v.Origem).HasMaxLength(100);
            e.Property(v => v.Status);
            // Relacionamentos
            e.HasOne(v => v.Cliente).WithMany(c => c.Vendas)
             .HasForeignKey(v => v.ClienteId).OnDelete(DeleteBehavior.Restrict);
            e.HasOne(v => v.Usuario).WithMany(u => u.Vendas)
             .HasForeignKey(v => v.UsuarioId).OnDelete(DeleteBehavior.Restrict);
            // Métodos de domínio não persistidos
            e.Ignore("RecalcularTotal");
        });

        // ── ItemVenda ─────────────────────────────────────────────────────────
        modelBuilder.Entity<ItemVenda>(e => {
            e.HasKey(i => i.Id);
            e.Property(i => i.PrecoUnitario).HasColumnType("decimal(10,2)");
            e.Property(i => i.Subtotal).HasColumnType("decimal(10,2)");
            e.HasOne(i => i.Venda).WithMany(v => v.ItensVenda)
             .HasForeignKey(i => i.VendaId).OnDelete(DeleteBehavior.Cascade);
            e.HasOne(i => i.Produto).WithMany()
             .HasForeignKey(i => i.ProdutoId).OnDelete(DeleteBehavior.Restrict);
        });

        // ── Pagamento (UML: + StatusPagamento, DataPagamento, CodigoTransacao, Observacao) ──
        modelBuilder.Entity<Pagamento>(e => {
            e.HasKey(p => p.Id);
            e.Property(p => p.Taxa).HasColumnType("decimal(5,2)");
            e.Property(p => p.ValorFinal).HasColumnType("decimal(10,2)");
            e.Property(p => p.StatusPagamento);
            e.Property(p => p.DataPagamento).IsRequired(false);
            // CodigoTransacao: código do gateway (Pix, PagSeguro, etc.)
            e.Property(p => p.CodigoTransacao).HasMaxLength(200).IsRequired(false);
            // Observacao: notas sobre o pagamento
            e.Property(p => p.Observacao).HasMaxLength(500).IsRequired(false);
            e.HasOne(p => p.Venda).WithOne(v => v.Pagamento)
             .HasForeignKey<Pagamento>(p => p.VendaId).OnDelete(DeleteBehavior.Cascade);
        });

        // ── Entrega (UML: DataEntrega, Taxa, ValorEntrega) ────────────────────
        modelBuilder.Entity<Entrega>(e => {
            e.HasKey(en => en.Id);
            // Taxa percentual da entrega
            e.Property(en => en.Taxa).HasColumnType("decimal(5,2)").HasDefaultValue(0m);
            // Valor monetário da entrega (novo campo UML)
            e.Property(en => en.ValorEntrega).HasColumnType("decimal(10,2)").HasDefaultValue(0m);
            e.Property(en => en.Horario).HasMaxLength(10);
            // DataEntrega renomeado de Data (UML)
            e.Property(en => en.DataEntrega).IsRequired();
            e.HasOne(en => en.Venda).WithOne(v => v.Entrega)
             .HasForeignKey<Entrega>(en => en.VendaId).IsRequired(false).OnDelete(DeleteBehavior.Cascade);
        });

        // ── VariacaoProduto (UML: + Custo) ────────────────────────────────────
        modelBuilder.Entity<VariacaoProduto>(e => {
            e.HasKey(v => v.Id);
            e.Property(v => v.Descricao).IsRequired().HasMaxLength(200);
            e.Property(v => v.PrecoVenda).HasColumnType("decimal(10,2)");
            e.Property(v => v.Custo).HasColumnType("decimal(10,2)").HasDefaultValue(0m);
            e.Property(v => v.Peso).HasColumnType("decimal(10,3)");
            e.HasOne(v => v.Produto).WithMany(p => p.VariacoesProduto)
             .HasForeignKey(v => v.ProdutoId).OnDelete(DeleteBehavior.Cascade);
            // MargemLucro é computed property, não persistida
            e.Ignore(v => v.MargemLucro);
        });

        // ── HistoricoPreco (UML: + MotivoAlteracao, DataFimVigencia) ──────────
        modelBuilder.Entity<HistoricoPreco>(e => {
            e.HasKey(h => h.Id);
            e.Property(h => h.PrecoAnterior).HasColumnType("decimal(10,2)");
            e.Property(h => h.MotivoAlteracao).HasMaxLength(300);
            e.Property(h => h.DataFimVigencia).IsRequired(false);
            e.HasOne(h => h.Produto).WithMany(p => p.HistoricoPreco)
             .HasForeignKey(h => h.ProdutoId).OnDelete(DeleteBehavior.Cascade);
        });

        // ── Estoque ───────────────────────────────────────────────────────────
        modelBuilder.Entity<Estoque>(e => {
            e.HasKey(es => es.Id);
            e.HasOne(es => es.Produto).WithOne(p => p.Estoque)
             .HasForeignKey<Estoque>(es => es.ProdutoId).OnDelete(DeleteBehavior.Cascade);
        });

        // ── MovimentacaoEstoque (TipoMovimentacao agora inclui ConsumoProprio e Perda) ──
        modelBuilder.Entity<MovimentacaoEstoque>(e => {
            e.HasKey(m => m.Id);
            e.Property(m => m.Motivo).HasMaxLength(300);
            e.HasOne(m => m.Estoque).WithMany(es => es.Movimentacoes)
             .HasForeignKey(m => m.EstoqueId).OnDelete(DeleteBehavior.Cascade);
        });

        // ── ConsumoProprio (RF04) ─────────────────────────────────────────────
        modelBuilder.Entity<ConsumoProprio>(e => {
            e.HasKey(c => c.Id);
            e.Property(c => c.Observacao).HasMaxLength(500);
            e.HasOne(c => c.Produto).WithMany()
             .HasForeignKey(c => c.ProdutoId).OnDelete(DeleteBehavior.Restrict);
            e.HasOne(c => c.Usuario).WithMany()
             .HasForeignKey(c => c.UsuarioId).OnDelete(DeleteBehavior.Restrict);
        });

        // ── PasswordResetToken (US16) ─────────────────────────────────────────
        modelBuilder.Entity<PasswordResetToken>(e => {
            e.HasKey(t => t.Id);
            e.Property(t => t.Email).IsRequired().HasMaxLength(256);
            e.Property(t => t.Token).IsRequired().HasMaxLength(512);
            e.HasIndex(t => t.Token);
        });
    }
}
