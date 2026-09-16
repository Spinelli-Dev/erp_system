namespace MaxiMassasAPI.Models;

// ============================================================================
// Enums — MaxiMassas API (Versão Final — alinhada ao diagrama UML completo)
// ============================================================================

public enum TipoUsuario { Administrador = 1, Operador = 2 }

/// <summary>
/// Status do ciclo de vida da Venda (UML: Status: string).
/// Separado do StatusPagamento (entidade Pagamento).
/// </summary>
public enum StatusVenda
{
    Nenhum = 0,
    Aberta = 1,
    EmProcessamento = 2,
    Paga = 3,
    EmEntrega = 4,
    Concluida = 5,
    Cancelada = 6
}

/// <summary>Status do pagamento — pertence à entidade Pagamento (UML).</summary>
public enum StatusPagamento { Pendente = 1, Pago = 2, Cancelado = 3 }

public enum TipoDesconto { Nenhum = 0, Valor = 1, Percentual = 2 }
public enum TipoEntrega { Retirada = 1, Entrega = 2 }

/// <summary>
/// Tipo de movimentação de estoque.
/// ConsumoProprio e Perda adicionados conforme diagrama UML.
/// </summary>
public enum TipoMovimentacao
{
    Entrada = 1,
    Saida = 2,
    ConsumoProprio = 3,
    Perda = 4
}

public enum TipoProduto { Massa = 1, Molho = 2, Recheio = 3, Bebida = 4, Outros = 5 }
public enum FormaPagamento { Dinheiro = 1, CartaoDebito = 2, CartaoCredito = 3, Pix = 4, Transferencia = 5, Outro = 6 }
