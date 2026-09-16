using FluentValidation;
using MaxiMassasAPI.DTOs.Request;

namespace MaxiMassasAPI.Validators;

public class EstoqueRequestValidator : AbstractValidator<EstoqueRequest>
{
    public EstoqueRequestValidator()
    {
        RuleFor(e => e.ProdutoId).GreaterThan(0);
        RuleFor(e => e.Quantidade).GreaterThanOrEqualTo(0);
        RuleFor(e => e.AlertaMinimo).GreaterThanOrEqualTo(0);
    }
}

public class MovimentacaoEstoqueRequestValidator : AbstractValidator<MovimentacaoEstoqueRequest>
{
    public MovimentacaoEstoqueRequestValidator()
    {
        RuleFor(m => m.EstoqueId).GreaterThan(0);
        RuleFor(m => m.Quantidade).GreaterThan(0).WithMessage("Quantidade deve ser maior que zero.");
        RuleFor(m => m.Motivo).NotEmpty().WithMessage("Motivo e obrigatorio.");
        RuleFor(m => m.Tipo).IsInEnum();
    }
}