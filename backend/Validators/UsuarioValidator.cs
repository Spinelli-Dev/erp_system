using FluentValidation;
using MaxiMassasAPI.DTOs.Request;
using MaxiMassasAPI.Services;

namespace MaxiMassasAPI.Validators;

public class UsuarioRequestValidator : AbstractValidator<UsuarioRequest>
{
    public UsuarioRequestValidator()
    {
        RuleFor(u => u.Nome).NotEmpty().WithMessage("Nome e obrigatorio.").MaximumLength(150);
        RuleFor(u => u.Login).NotEmpty().WithMessage("Login e obrigatorio.")
            .MinimumLength(3).WithMessage("O login deve ter pelo menos 3 caracteres.").MaximumLength(50)
            .Matches("^[a-zA-Z0-9_]+$").WithMessage("Login deve conter apenas letras, numeros e underscore.");
        // Mesma regra do cadastro de clientes do app (PoliticaSenha).
        RuleFor(u => u.Senha).Must(s => PoliticaSenha.Validar(s) is null)
            .WithMessage(u => PoliticaSenha.Validar(u.Senha) ?? string.Empty);
        RuleFor(u => u.Tipo).IsInEnum().WithMessage("Tipo de usuario invalido.");
        RuleFor(u => u.Email).EmailAddress().WithMessage("E-mail invalido.").MaximumLength(150)
            .When(u => !string.IsNullOrWhiteSpace(u.Email));
        RuleFor(u => u.Telefone).MaximumLength(20);
    }
}

public class UsuarioUpdateRequestValidator : AbstractValidator<UsuarioUpdateRequest>
{
    public UsuarioUpdateRequestValidator()
    {
        RuleFor(u => u.Nome).NotEmpty().WithMessage("Nome e obrigatorio.").MaximumLength(150);
        RuleFor(u => u.Senha).Must(s => PoliticaSenha.Validar(s) is null)
            .WithMessage(u => PoliticaSenha.Validar(u.Senha) ?? string.Empty)
            .When(u => !string.IsNullOrEmpty(u.Senha));
        RuleFor(u => u.Tipo).IsInEnum().WithMessage("Tipo de usuario invalido.");
        RuleFor(u => u.Email).EmailAddress().WithMessage("E-mail invalido.").MaximumLength(150)
            .When(u => !string.IsNullOrWhiteSpace(u.Email));
        RuleFor(u => u.Telefone).MaximumLength(20);
    }
}

public class PerfilUsuarioRequestValidator : AbstractValidator<PerfilUsuarioRequest>
{
    public PerfilUsuarioRequestValidator()
    {
        RuleFor(u => u.Nome).NotEmpty().WithMessage("Nome e obrigatorio.").MaximumLength(150);
        RuleFor(u => u.Email).EmailAddress().WithMessage("E-mail invalido.").MaximumLength(150)
            .When(u => !string.IsNullOrWhiteSpace(u.Email));
        RuleFor(u => u.Telefone).MaximumLength(20);
    }
}
