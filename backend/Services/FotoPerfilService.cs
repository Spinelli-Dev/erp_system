// Foto de perfil dos usuários do painel: valida o arquivo enviado e o transforma num quadrado
// de 256x256 em JPEG (~20–40 KB), que é o que fica guardado no banco.
using SkiaSharp;

namespace MaxiMassasAPI.Services;

public interface IFotoPerfilService
{
    /// <summary>Tamanho máximo do arquivo enviado (antes de reduzir).</summary>
    long TamanhoMaximoBytes { get; }

    /// <summary>Recorta o centro, reduz para 256x256 e grava como JPEG. Lança InvalidOperationException se não for imagem válida.</summary>
    Task<byte[]> PrepararAsync(Stream arquivo, long tamanho);
}

public class FotoPerfilService : IFotoPerfilService
{
    public long TamanhoMaximoBytes => 2 * 1024 * 1024; // 2 MB

    private const int Lado = 256;
    private const int QualidadeJpeg = 85;

    public async Task<byte[]> PrepararAsync(Stream arquivo, long tamanho)
    {
        if (tamanho <= 0) throw new InvalidOperationException("Escolha uma imagem.");
        if (tamanho > TamanhoMaximoBytes) throw new InvalidOperationException("A foto pode ter no máximo 2 MB.");

        using var memoria = new MemoryStream();
        await arquivo.CopyToAsync(memoria);
        memoria.Position = 0;

        // Decodifica de fato (JPEG, PNG, WebP, GIF, BMP): o tipo informado pelo navegador não é confiável.
        using var original = SKBitmap.Decode(memoria)
            ?? throw new InvalidOperationException("O arquivo não é uma imagem válida. Use JPG, PNG ou WebP.");

        // Quadrado central (a foto aparece em círculo no menu) e redução para 256x256.
        var menorLado = Math.Min(original.Width, original.Height);
        var recorte = new SKRectI(
            (original.Width - menorLado) / 2, (original.Height - menorLado) / 2,
            (original.Width - menorLado) / 2 + menorLado, (original.Height - menorLado) / 2 + menorLado);

        using var quadrado = new SKBitmap(menorLado, menorLado);
        if (!original.ExtractSubset(quadrado, recorte))
            throw new InvalidOperationException("Não foi possível processar a imagem.");

        using var reduzida = quadrado.Resize(new SKImageInfo(Lado, Lado), SKFilterQuality.High)
            ?? throw new InvalidOperationException("Não foi possível processar a imagem.");

        // JPEG não tem transparência: fundo branco atrás de PNGs transparentes.
        using var superficie = SKSurface.Create(new SKImageInfo(Lado, Lado));
        superficie.Canvas.Clear(SKColors.White);
        superficie.Canvas.DrawBitmap(reduzida, 0, 0);
        using var imagem = superficie.Snapshot();
        using var jpeg = imagem.Encode(SKEncodedImageFormat.Jpeg, QualidadeJpeg);
        return jpeg.ToArray();
    }
}
