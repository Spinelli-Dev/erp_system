// VendaValidator — atualizado para validar novos campos UML (Frete, Observacao).
using FluentValidation;
using MaxiMassasAPI.DTOs.Request;

namespace MaxiMassasAPI.Validators;

public class VendaRequestValidator : AbstractValidator<VendaRequest>
{
    public VendaRequestValidator()
    {
        RuleFor(v => v.ClienteId).GreaterThan(0).WithMessage("Cliente e obrigatorio.");
        RuleFor(v => v.Itens).NotEmpty().WithMessage("A venda deve ter pelo menos 1 item.");
        RuleForEach(v => v.Itens).ChildRules(item => {
            item.RuleFor(i => i.ProdutoId).GreaterThan(0).WithMessage("Produto invalido.");
            item.RuleFor(i => i.Quantidade).GreaterThan(0).WithMessage("Quantidade deve ser maior que zero.");
        });
        RuleFor(v => v.Desconto).GreaterThanOrEqualTo(0).WithMessage("Desconto nao pode ser negativo.");
        // UML: Frete: decimal
        RuleFor(v => v.Frete).GreaterThanOrEqualTo(0).WithMessage("Frete nao pode ser negativo.");
        // UML: Observacao: string
        RuleFor(v => v.Observacao).MaximumLength(500).When(v => v.Observacao != null)
            .WithMessage("Observacao deve ter no maximo 500 caracteres.");
        RuleFor(v => v.Pagamento).NotNull().WithMessage("Dados de pagamento sao obrigatorios.");
    }
}
