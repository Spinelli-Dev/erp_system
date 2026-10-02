// US16 — Redefinição de Senha ("Esqueci minha senha"), para dois públicos:
//   - Usuario (painel): link por e-mail com token longo, válido por 1 hora;
//   - Cliente (app): código de 6 dígitos por e-mail, válido por 15 minutos, com no máximo 5 tentativas.
// Uso único nos dois casos. O que se guarda é o HASH (SHA-256) do token/código, nunca o valor em si:
// quem lesse a tabela não conseguiria redefinir a senha de ninguém.
namespace MaxiMassasAPI.Models;

public enum DestinoRedefinicao { Usuario = 1, Cliente = 2 }

public class PasswordResetToken
{
    public int Id { get; set; }

    /// <summary>E-mail para onde o token/código foi enviado.</summary>
    public string Email { get; set; } = string.Empty;

    /// <summary>Hash SHA-256 (hex) do token do link ou do código de 6 dígitos.</summary>
    public string Token { get; set; } = string.Empty;

    /// <summary>De quem é a senha: usuário do painel ou cliente do app.</summary>
    public DestinoRedefinicao Destino { get; set; } = DestinoRedefinicao.Usuario;

    /// <summary>Id do Usuario ou do Cliente (conforme Destino).</summary>
    public int ReferenciaId { get; set; }

    /// <summary>Data/hora de expiração do token.</summary>
    public DateTime ExpiresAt { get; set; }

    /// <summary>Indica se o token já foi utilizado (uso único) ou invalidado.</summary>
    public bool Usado { get; set; } = false;

    /// <summary>Códigos errados digitados (só para o código do app; no limite, o código deixa de valer).</summary>
    public int Tentativas { get; set; }

    /// <summary>Data de criação para auditoria.</summary>
    public DateTime CriadoEm { get; set; } = DateTime.Now;
}
