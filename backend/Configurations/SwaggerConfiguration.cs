using Microsoft.OpenApi.Models;

namespace MaxiMassasAPI.Configurations;

public static class SwaggerConfiguration
{
    public static IServiceCollection AddSwaggerConfiguration(this IServiceCollection services)
    {
        services.AddSwaggerGen(c =>
        {
            c.SwaggerDoc("v1", new OpenApiInfo
            {
                Title = "MaxiMassas API",
                Version = "v1",
                Description = "API backend do sistema de gestao MaxiMassas. Use Basic Auth com login:senha."
            });

            c.AddSecurityDefinition("basic", new OpenApiSecurityScheme
            {
                Type = SecuritySchemeType.Http,
                Scheme = "basic",
                Description = "Informe suas credenciais Basic (login:senha em base64)."
            });

            c.AddSecurityRequirement(new OpenApiSecurityRequirement
            {
                {
                    new OpenApiSecurityScheme { Reference = new OpenApiReference { Type = ReferenceType.SecurityScheme, Id = "basic" } },
                    Array.Empty<string>()
                }
            });
        });

        return services;
    }
}