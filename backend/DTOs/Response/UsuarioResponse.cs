namespace MaxiMassasAPI.DTOs.Response;
using MaxiMassasAPI.Models;

public class UsuarioResponse
{
    public int Id { get; set; }
    public string Nome { get; set; } = string.Empty;
    public string Login { get; set; } = string.Empty;
    public TipoUsuario Tipo { get; set; }
    public string TipoDescricao => Tipo.ToString();
    public string? Email { get; set; }
    public string? Telefone { get; set; }
    public bool Ativo { get; set; }
    /// <summary>Data da foto atual (nula = sem foto). A imagem em si sai por /Foto/{id}, não no JSON.</summary>
    public DateTime? FotoAtualizadaEm { get; set; }
    public bool TemFoto => FotoAtualizadaEm is not null;
}
