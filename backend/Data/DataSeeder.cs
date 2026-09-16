// Seed: aplica migrations e cria o admin padrao se nao existir.
using MaxiMassasAPI.Models;
using Microsoft.EntityFrameworkCore;

namespace MaxiMassasAPI.Data;

public static class DataSeeder
{
    public static async Task SeedAsync(AppDbContext context, ILogger logger)
    {
        try
        {
            await context.Database.MigrateAsync();
            logger.LogInformation("Migrations aplicadas com sucesso.");

            bool adminExiste = await context.Usuarios.AnyAsync(u => u.Login == "admin");
            if (!adminExiste)
            {
                var admin = new Usuario
                {
                    Nome = "Administrador",
                    Login = "admin",
                    Senha = BCrypt.Net.BCrypt.HashPassword("admin123"),
                    Tipo = TipoUsuario.Administrador
                };
                context.Usuarios.Add(admin);
                await context.SaveChangesAsync();
                logger.LogInformation("Usuario administrador padrao criado. Login: admin | Senha: admin123");
            }
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Erro ao executar o seed do banco de dados.");
            throw;
        }
    }
}