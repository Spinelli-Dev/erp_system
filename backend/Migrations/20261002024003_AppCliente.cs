using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MaxiMassasAPI.Migrations
{
    /// <inheritdoc />
    public partial class AppCliente : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterColumn<int>(
                name: "UsuarioId",
                table: "Vendas",
                type: "int",
                nullable: true,
                oldClrType: typeof(int),
                oldType: "int");

            migrationBuilder.AlterColumn<string>(
                name: "Horario",
                table: "Entregas",
                type: "nvarchar(30)",
                maxLength: 30,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(10)",
                oldMaxLength: 10);

            migrationBuilder.AddColumn<string>(
                name: "Bairro",
                table: "Entregas",
                type: "nvarchar(100)",
                maxLength: 100,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Cep",
                table: "Entregas",
                type: "nvarchar(9)",
                maxLength: 9,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Complemento",
                table: "Entregas",
                type: "nvarchar(100)",
                maxLength: 100,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Logradouro",
                table: "Entregas",
                type: "nvarchar(200)",
                maxLength: 200,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Numero",
                table: "Entregas",
                type: "nvarchar(20)",
                maxLength: 20,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Email",
                table: "Clientes",
                type: "nvarchar(150)",
                maxLength: 150,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "SenhaHash",
                table: "Clientes",
                type: "nvarchar(256)",
                maxLength: 256,
                nullable: true);

            migrationBuilder.CreateTable(
                name: "ConfiguracoesEntrega",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false),
                    TaxaEntrega = table.Column<decimal>(type: "decimal(10,2)", nullable: false),
                    PedidoMinimoEntregaGratis = table.Column<decimal>(type: "decimal(10,2)", nullable: false),
                    AtualizadoEm = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ConfiguracoesEntrega", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "EnderecosCliente",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Logradouro = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: false),
                    Numero = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: false),
                    Complemento = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: true),
                    Bairro = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    Cep = table.Column<string>(type: "nvarchar(9)", maxLength: 9, nullable: true),
                    Principal = table.Column<bool>(type: "bit", nullable: false),
                    ClienteId = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_EnderecosCliente", x => x.Id);
                    table.ForeignKey(
                        name: "FK_EnderecosCliente_Clientes_ClienteId",
                        column: x => x.ClienteId,
                        principalTable: "Clientes",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.InsertData(
                table: "ConfiguracoesEntrega",
                columns: new[] { "Id", "AtualizadoEm", "PedidoMinimoEntregaGratis", "TaxaEntrega" },
                values: new object[] { 1, new DateTime(2026, 10, 1, 0, 0, 0, 0, DateTimeKind.Unspecified), 0m, 0m });

            migrationBuilder.CreateIndex(
                name: "IX_Clientes_Email",
                table: "Clientes",
                column: "Email",
                unique: true,
                filter: "[Email] IS NOT NULL");

            migrationBuilder.CreateIndex(
                name: "IX_EnderecosCliente_ClienteId",
                table: "EnderecosCliente",
                column: "ClienteId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "ConfiguracoesEntrega");

            migrationBuilder.DropTable(
                name: "EnderecosCliente");

            migrationBuilder.DropIndex(
                name: "IX_Clientes_Email",
                table: "Clientes");

            migrationBuilder.DropColumn(
                name: "Bairro",
                table: "Entregas");

            migrationBuilder.DropColumn(
                name: "Cep",
                table: "Entregas");

            migrationBuilder.DropColumn(
                name: "Complemento",
                table: "Entregas");

            migrationBuilder.DropColumn(
                name: "Logradouro",
                table: "Entregas");

            migrationBuilder.DropColumn(
                name: "Numero",
                table: "Entregas");

            migrationBuilder.DropColumn(
                name: "Email",
                table: "Clientes");

            migrationBuilder.DropColumn(
                name: "SenhaHash",
                table: "Clientes");

            migrationBuilder.AlterColumn<int>(
                name: "UsuarioId",
                table: "Vendas",
                type: "int",
                nullable: false,
                defaultValue: 0,
                oldClrType: typeof(int),
                oldType: "int",
                oldNullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "Horario",
                table: "Entregas",
                type: "nvarchar(10)",
                maxLength: 10,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(30)",
                oldMaxLength: 30);
        }
    }
}
