using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MaxiMassasAPI.Migrations
{
    /// <inheritdoc />
    public partial class EnderecoCidadeEstado : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "Cidade",
                table: "Entregas",
                type: "nvarchar(100)",
                maxLength: 100,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Estado",
                table: "Entregas",
                type: "nvarchar(2)",
                maxLength: 2,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Cidade",
                table: "EnderecosCliente",
                type: "nvarchar(100)",
                maxLength: 100,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "Estado",
                table: "EnderecosCliente",
                type: "nvarchar(2)",
                maxLength: 2,
                nullable: false,
                defaultValue: "");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Cidade",
                table: "Entregas");

            migrationBuilder.DropColumn(
                name: "Estado",
                table: "Entregas");

            migrationBuilder.DropColumn(
                name: "Cidade",
                table: "EnderecosCliente");

            migrationBuilder.DropColumn(
                name: "Estado",
                table: "EnderecosCliente");
        }
    }
}
