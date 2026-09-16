using FluentValidation;
using MaxiMassasAPI.DTOs.Request;

namespace MaxiMassasAPI.Validators;

public class ProdutoRequestValidator : AbstractValidator<ProdutoRequest>
{
    public ProdutoRequestValidator()
    {
        RuleFor(p => p.Nome).NotEmpty().MaximumLength(150);
        RuleFor(p => p.PrecoVenda).GreaterThan(0).WithMessage("Preco de venda deve ser maior que zero.");
        RuleFor(p => p.Custo).GreaterThanOrEqualTo(0).WithMessage("Custo nao pode ser negativo.");
        RuleFor(p => p.Peso).GreaterThan(0).WithMessage("Peso deve ser maior que zero.");
        RuleFor(p => p.Tipo).IsInEnum().WithMessage("Tipo de produto invalido.");
    }
}