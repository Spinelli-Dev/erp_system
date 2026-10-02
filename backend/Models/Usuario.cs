// Representa um usuario do sistema. A senha e armazenada como hash BCrypt.
namespace MaxiMassasAPI.Models;

public class Usuario
{
    public int Id { get; set; }
    public string Nome { get; set; } = string.Empty;
    public string Login { get; set; } = string.Empty;
    /// <summary>Senha hasheada com BCrypt. Nunca retornar nos responses.</summary>
    public string Senha { get; set; } = string.Empty;
    public TipoUsuario Tipo { get; set; }

    // ── Perfil (editado pelo próprio usuário em "Meu perfil") ────────────────
    /// <summary>E-mail (único quando preenchido).</summary>
    public string? Email { get; set; }
    public string? Telefone { get; set; }
    /// <summary>Foto já recortada e reduzida para 256x256 JPEG (ver FotoPerfilService). Nunca retornar nos responses.</summary>
    public byte[]? Foto { get; set; }
    /// <summary>Quando a foto mudou: entra na URL da imagem para o navegador não mostrar a antiga do cache.</summary>
    public DateTime? FotoAtualizadaEm { get; set; }

    /// <summary>Desativado não entra no sistema, mas continua no histórico (vendas registradas por ele).</summary>
    public bool Ativo { get; set; } = true;
    public ICollection<Venda> Vendas { get; set; } = new List<Venda>();
}