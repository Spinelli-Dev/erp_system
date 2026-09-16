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
    public ICollection<Venda> Vendas { get; set; } = new List<Venda>();
}