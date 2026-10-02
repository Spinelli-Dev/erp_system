using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MaxiMassasAPI.Migrations
{
    /// <inheritdoc />
    public partial class ProdutoSaborObservacao : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "Observacao",
                table: "Produtos",
                type: "nvarchar(500)",
                maxLength: 500,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Sabor",
                table: "Produtos",
                type: "nvarchar(100)",
                maxLength: 100,
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Observacao",
                table: "Produtos");

            migrationBuilder.DropColumn(
                name: "Sabor",
                table: "Produtos");
        }
    }
}
