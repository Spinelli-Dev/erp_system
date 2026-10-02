// Conversões entre o que a tela mostra/recebe ("Massas", "R$ 18,90", "250g") e os tipos do domínio.
using System.Globalization;
using System.Text.RegularExpressions;
using MaxiMassasAPI.Models;

namespace MaxiMassasAPI.Pages;

public static class PainelFormatos
{
    public static readonly CultureInfo PtBr = new("pt-BR");

    /// <summary>Alerta mínimo dos produtos novos (mesmo valor dos produtos já cadastrados).</summary>
    public const int AlertaMinimoPadrao = 5;

    private static readonly Dictionary<TipoProduto, string> RotulosTipo = new()
    {
        [TipoProduto.Massa] = "Massas",
        [TipoProduto.Molho] = "Molhos",
        [TipoProduto.Recheio] = "Recheios",
        [TipoProduto.Bebida] = "Bebidas",
        [TipoProduto.Outros] = "Outros",
    };

    public static IEnumerable<KeyValuePair<TipoProduto, string>> Tipos => RotulosTipo;

    public static string RotuloTipo(TipoProduto tipo) => RotulosTipo.TryGetValue(tipo, out var r) ? r : tipo.ToString();

    public static string Moeda(decimal valor) => valor.ToString("C", PtBr);

    /// <summary>"250g" (peso guardado em gramas).</summary>
    public static string Peso(decimal gramas) => $"{gramas.ToString("0.##", PtBr)}g";

    /// <summary>"R$ 1.234,56", "18,90" ou "18.90" → 18.90. Null se não for um número.</summary>
    public static decimal? LerMoeda(string? texto)
    {
        var limpo = Regex.Replace(texto ?? string.Empty, @"[^\d,.\-]", string.Empty);
        if (limpo.Length == 0) return null;
        // Com vírgula, ela é o decimal e os pontos são de milhar (padrão brasileiro).
        if (limpo.Contains(',')) limpo = limpo.Replace(".", string.Empty).Replace(',', '.');
        return decimal.TryParse(limpo, NumberStyles.Number, CultureInfo.InvariantCulture, out var v) ? Math.Round(v, 2) : null;
    }

    /// <summary>"250g", "250", "0,5kg" → gramas. Null se não for um número.</summary>
    public static decimal? LerPeso(string? texto)
    {
        var t = (texto ?? string.Empty).Trim().ToLowerInvariant();
        var emKg = t.EndsWith("kg");
        var valor = LerMoeda(Regex.Replace(t, "[a-z ]", string.Empty));
        return valor is null ? null : emKg ? valor * 1000 : valor;
    }
}
