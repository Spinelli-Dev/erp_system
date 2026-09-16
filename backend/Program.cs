// Program.cs — MaxiMassas API
// Configuração de todos os serviços, middlewares e pipeline da aplicação.
using FluentValidation;
using FluentValidation.AspNetCore;
using MaxiMassasAPI.Configurations;
using MaxiMassasAPI.Data;
using MaxiMassasAPI.Integrations;
using MaxiMassasAPI.Middleware;
using MaxiMassasAPI.Repositories;
using MaxiMassasAPI.Services;
using Microsoft.AspNetCore.Authentication;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

// ============================================================================
// 1. BANCO DE DADOS
// ============================================================================
builder.Services.AddDbContext<AppDbContext>(o =>
    o.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

// ============================================================================
// 2. AUTENTICAÇÃO — Basic Auth com handler customizado
// ============================================================================
builder.Services.AddAuthentication("BasicAuth")
    .AddScheme<AuthenticationSchemeOptions, BasicAuthHandler>("BasicAuth", null);
builder.Services.AddAuthorization();

// ============================================================================
// 3. AUTOMAPPER — mapeamento de entidades ↔ DTOs
// ============================================================================
builder.Services.AddAutoMapper(typeof(AutoMapperProfile));

// ============================================================================
// 4. FLUENTVALIDATION — validação de requests
// ============================================================================
builder.Services.AddFluentValidationAutoValidation();
builder.Services.AddValidatorsFromAssemblyContaining<Program>();

// ============================================================================
// 5. HTTP CLIENTS — ViaCEP (IHttpClientFactory evita socket exhaustion)
// ============================================================================
var viacepTimeout = builder.Configuration.GetValue<int>("ViaCep:TimeoutSeconds", 10);
builder.Services.AddHttpClient("ViaCep", client => {
    client.BaseAddress = new Uri(builder.Configuration["ViaCep:BaseUrl"]!);
    client.Timeout = TimeSpan.FromSeconds(viacepTimeout);
});

// ============================================================================
// 6. REPOSITÓRIOS
// ============================================================================
builder.Services.AddScoped(typeof(IRepository<>), typeof(Repository<>));
builder.Services.AddScoped<IUsuarioRepository, UsuarioRepository>();
builder.Services.AddScoped<IClienteRepository, ClienteRepository>();
builder.Services.AddScoped<IProdutoRepository, ProdutoRepository>();
builder.Services.AddScoped<IVendaRepository, VendaRepository>();
builder.Services.AddScoped<IEstoqueRepository, EstoqueRepository>();

// RF04 — Repositório de Consumo Próprio
builder.Services.AddScoped<IConsumoProprioRepository, ConsumoProprioRepository>();
// ============================================================================
// 7. SERVICES DE NEGÓCIO
// ============================================================================
builder.Services.AddScoped<IUsuarioService, UsuarioService>();
builder.Services.AddScoped<IClienteService, ClienteService>();
builder.Services.AddScoped<IProdutoService, ProdutoService>();
builder.Services.AddScoped<IEstoqueService, EstoqueService>();
builder.Services.AddScoped<IVendaService, VendaService>();
builder.Services.AddScoped<IVariacaoProdutoService, VariacaoProdutoService>();
builder.Services.AddScoped<IRelatorioService, RelatorioService>();
builder.Services.AddScoped<IViaCepService, ViaCepService>();

// RF04 — Service de Consumo Próprio
builder.Services.AddScoped<IConsumoProprioService, ConsumoProprioService>();

// US14 — Service de Exportação (Excel + PDF)
builder.Services.AddScoped<IExportacaoService, ExportacaoService>();

// US16 — Service de Autenticação / Reset de Senha
builder.Services.AddScoped<IAuthService, AuthService>();

// US16 — Service de E-mail (mockável via appsettings.json EmailSettings:MockMode)
builder.Services.AddScoped<IEmailService, EmailService>();

// ============================================================================
// 8. RNF03 — BACKUP AUTOMÁTICO (BackgroundService)
// Roda como hosted service em background, sem bloquear as requisições da API.
// ============================================================================
builder.Services.AddHostedService<BackupService>();

// ============================================================================
// 9. CONTROLLERS + SWAGGER
// ============================================================================
builder.Services.AddControllers()
    .AddJsonOptions(o => o.JsonSerializerOptions.Converters.Add(
        new System.Text.Json.Serialization.JsonStringEnumConverter()));
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerConfiguration();

// ============================================================================
// 10. CORS — liberado para todos (ajustar origins em produção)
// ============================================================================
builder.Services.AddCors(o => o.AddPolicy("AllowAll",
    p => p.AllowAnyOrigin().AllowAnyMethod().AllowAnyHeader()));

builder.Logging.ClearProviders();
builder.Logging.AddConsole();

var app = builder.Build();

// ============================================================================
// SEED: aplica migrations e cria admin padrão se banco estiver vazio
// ============================================================================
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    var logger = scope.ServiceProvider.GetRequiredService<ILogger<Program>>();
    await DataSeeder.SeedAsync(db, logger);
}

// ============================================================================
// PIPELINE DE MIDDLEWARES (ordem importa!)
// ============================================================================
app.UseMiddleware<ErrorHandlingMiddleware>();

app.UseSwagger();
app.UseSwaggerUI(c => {
    c.SwaggerEndpoint("/swagger/v1/swagger.json", "MaxiMassas API v1");
    c.RoutePrefix = "swagger";
    c.DocumentTitle = "MaxiMassas API";
});

app.UseHttpsRedirection();
app.UseCors("AllowAll");
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();
app.Run();
