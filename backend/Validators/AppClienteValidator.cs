using FluentValidation;
using MaxiMassasAPI.DTOs.Request;
using MaxiMassasAPI.Models;

namespace MaxiMassasAPI.Validators;

public class CadastroClienteAppRequestValidator : AbstractValidator<CadastroClienteAppRequest>
{
    public const int TamanhoMinimoSenha = 8;

    public CadastroClienteAppRequestValidator()
    {
        RuleFor(c => c.Nome).NotEmpty().WithMessage("Nome e obrigatorio.").MaximumLength(150);
        RuleFor(c => c.Email).NotEmpty().WithMessage("E-mail e obrigatorio.")
            .EmailAddress().WithMessage("E-mail invalido.").MaximumLength(150);
        RuleFor(c => c.Telefone).NotEmpty().WithMessage("Telefone e obrigatorio.").MaximumLength(20);
        // Mesma regra do checklist do app (core/validators.dart). Vale só para senhas novas:
        // o login não confere formato, então contas antigas continuam entrando.
        RuleFor(c => c.Senha).NotEmpty().WithMessage("Senha e obrigatoria.")
            .MinimumLength(TamanhoMinimoSenha).WithMessage($"A senha deve ter pelo menos {TamanhoMinimoSenha} caracteres.")
            .Matches(@"\p{L}").WithMessage("A senha deve ter pelo menos uma letra.")
            .Matches(@"\d").WithMessage("A senha deve ter pelo menos um numero.");
    }
}

public class AtualizarPerfilAppRequestValidator : AbstractValidator<AtualizarPerfilAppRequest>
{
    public AtualizarPerfilAppRequestValidator()
    {
        RuleFor(c => c.Nome).NotEmpty().WithMessage("Nome e obrigatorio.").MaximumLength(150);
        RuleFor(c => c.Email).NotEmpty().WithMessage("E-mail e obrigatorio.")
            .EmailAddress().WithMessage("E-mail invalido.").MaximumLength(150);
        RuleFor(c => c.Telefone).NotEmpty().WithMessage("Telefone e obrigatorio.").MaximumLength(20);
    }
}

public class EnderecoAppRequestValidator : AbstractValidator<EnderecoAppRequest>
{
    // Mesma lista do app (core/validators.dart).
    private static readonly HashSet<string> Ufs = new(StringComparer.OrdinalIgnoreCase)
    {
        "AC", "AL", "AP", "AM", "BA", "CE", "DF", "ES", "GO", "MA", "MT", "MS", "MG", "PA",
        "PB", "PR", "PE", "PI", "RJ", "RN", "RS", "RO", "RR", "SC", "SP", "SE", "TO"
    };

    public EnderecoAppRequestValidator()
    {
        RuleFor(e => e.Logradouro).NotEmpty().WithMessage("Rua e obrigatoria.").MaximumLength(200);
        RuleFor(e => e.Numero).NotEmpty().WithMessage("Numero e obrigatorio.").MaximumLength(20);
        RuleFor(e => e.Complemento).MaximumLength(100);
        RuleFor(e => e.Bairro).NotEmpty().WithMessage("Bairro e obrigatorio.").MaximumLength(100);
        RuleFor(e => e.Cep).NotEmpty().WithMessage("CEP e obrigatorio.")
            .Must(cep => (cep ?? string.Empty).Count(char.IsDigit) == 8).WithMessage("CEP invalido.");
        RuleFor(e => e.Cidade).NotEmpty().WithMessage("Cidade e obrigatoria.").MaximumLength(100);
        RuleFor(e => e.Estado).NotEmpty().WithMessage("Estado e obrigatorio.")
            .Must(uf => Ufs.Contains(uf.Trim())).WithMessage("Estado invalido: use a sigla da UF (ex.: SP).");
    }
}

public class PedidoAppRequestValidator : AbstractValidator<PedidoAppRequest>
{
    public PedidoAppRequestValidator()
    {
        RuleFor(p => p.Itens).NotEmpty().WithMessage("O pedido precisa de pelo menos um item.");
        RuleForEach(p => p.Itens).ChildRules(i =>
        {
            i.RuleFor(x => x.ProdutoId).GreaterThan(0).WithMessage("Produto invalido.");
            i.RuleFor(x => x.Quantidade).GreaterThan(0).WithMessage("Quantidade deve ser maior que zero.");
        });
        RuleFor(p => p.TipoEntrega).IsInEnum().WithMessage("Tipo de entrega invalido.");
        RuleFor(p => p.FormaPagamento).IsInEnum().WithMessage("Forma de pagamento invalida.");
        RuleFor(p => p.Endereco).NotNull().WithMessage("Informe o endereco de entrega.")
            .When(p => p.TipoEntrega == TipoEntrega.Entrega);
        RuleFor(p => p.Endereco!).SetValidator(new EnderecoAppRequestValidator())
            .When(p => p.TipoEntrega == TipoEntrega.Entrega && p.Endereco is not null);
        RuleFor(p => p.Observacao).MaximumLength(500);
        RuleFor(p => p.Horario).MaximumLength(30);
    }
}
