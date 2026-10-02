// Regra de senha nova (cadastro, redefinição e troca): a mesma do cadastro de clientes do app —
// pelo menos 8 caracteres, uma letra e um número. Senhas antigas continuam entrando (o login não confere formato).
using System.Text.RegularExpressions;

namespace MaxiMassasAPI.Services;

public static class PoliticaSenha
{
    public const int TamanhoMinimo = 8;
    public const string Descricao = "pelo menos 8 caracteres, com letras e números";

    /// <summary>null se a senha atende à regra; senão, o motivo.</summary>
    public static string? Validar(string? senha)
    {
        if (string.IsNullOrEmpty(senha)) return "Informe a senha.";
        if (senha.Length < TamanhoMinimo) return $"A senha deve ter pelo menos {TamanhoMinimo} caracteres.";
        if (!Regex.IsMatch(senha, @"\p{L}")) return "A senha deve ter pelo menos uma letra.";
        if (!Regex.IsMatch(senha, @"\d")) return "A senha deve ter pelo menos um número.";
        return null;
    }
}
