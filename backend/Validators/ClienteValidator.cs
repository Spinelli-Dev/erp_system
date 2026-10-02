// ClienteValidator — atualizado com validacao de CPF (UML: Cpf: string).
using FluentValidation;
using MaxiMassasAPI.DTOs.Request;
using System.Text.RegularExpressions;

namespace MaxiMassasAPI.Validators;

public class ClienteRequestValidator : AbstractValidator<ClienteRequest>
{
    public ClienteRequestValidator()
    {
        RuleFor(c => c.Nome)
            .NotEmpty().WithMessage("Nome e obrigatorio.")
            .MaximumLength(150);

        RuleFor(c => c.Telefone)
            .NotEmpty().WithMessage("Telefone e obrigatorio.")
            .Must(t => {
                var n = Regex.Replace(t ?? "", @"\D", "");
                return n.Length >= 10 && n.Length <= 11;
            }).WithMessage("Telefone invalido. Use DDD + numero (10 ou 11 digitos).");

        // UML: Cpf: string — validacao de formato quando informado
        RuleFor(c => c.Cpf)
            .Must(cpf => {
                if (string.IsNullOrEmpty(cpf)) return true; // opcional
                var numeros = Regex.Replace(cpf, @"\D", "");
                return numeros.Length == 11;
            }).WithMessage("CPF invalido. Use 11 digitos numericos.")
            .When(c => c.Cpf != null);

        RuleFor(c => c.CEP)
            .NotEmpty().WithMessage("CEP e obrigatorio.")
            .Matches(@"^\d{5}-?\d{3}$").WithMessage("CEP invalido. Use 00000-000.");

        RuleFor(c => c.Numero)
            .NotEmpty().WithMessage("Numero e obrigatorio.")
            .MaximumLength(20);

        RuleFor(c => c.Complemento).MaximumLength(100);
        RuleFor(c => c.Observacao).MaximumLength(500);
        RuleFor(c => c.Logradouro).MaximumLength(200);
        RuleFor(c => c.Bairro).MaximumLength(100);
        RuleFor(c => c.Cidade).MaximumLength(100);
        RuleFor(c => c.Estado).Matches("^[A-Za-z]{2}$").WithMessage("UF deve ter 2 letras (ex.: SP).")
            .When(c => !string.IsNullOrWhiteSpace(c.Estado));
    }
}

/// <summary>O PUT valida igual ao cadastro (antes não validava nada).</summary>
public class ClienteUpdateRequestValidator : AbstractValidator<ClienteUpdateRequest>
{
    public ClienteUpdateRequestValidator() => Include(new ClienteRequestValidator());
}
