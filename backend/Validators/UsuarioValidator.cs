using FluentValidation;
using MaxiMassasAPI.DTOs.Request;

namespace MaxiMassasAPI.Validators;

public class UsuarioRequestValidator : AbstractValidator<UsuarioRequest>
{
    public UsuarioRequestValidator()
    {
        RuleFor(u => u.Nome).NotEmpty().WithMessage("Nome e obrigatorio.").MaximumLength(150);
        RuleFor(u => u.Login).NotEmpty().WithMessage("Login e obrigatorio.")
            .MinimumLength(3).MaximumLength(50)
            .Matches("^[a-zA-Z0-9_]+$").WithMessage("Login deve conter apenas letras, numeros e underscore.");
        RuleFor(u => u.Senha).NotEmpty().WithMessage("Senha e obrigatoria.").MinimumLength(6);
        RuleFor(u => u.Tipo).IsInEnum().WithMessage("Tipo de usuario invalido.");
    }
}