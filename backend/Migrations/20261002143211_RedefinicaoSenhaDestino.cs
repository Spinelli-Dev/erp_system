using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MaxiMassasAPI.Migrations
{
    /// <inheritdoc />
    public partial class RedefinicaoSenhaDestino : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "Destino",
                table: "PasswordResetTokens",
                type: "int",
                nullable: false,
                defaultValue: 1);

            migrationBuilder.AddColumn<int>(
                name: "ReferenciaId",
                table: "PasswordResetTokens",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "Tentativas",
                table: "PasswordResetTokens",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.CreateIndex(
                name: "IX_PasswordResetTokens_Destino_ReferenciaId",
                table: "PasswordResetTokens",
                columns: new[] { "Destino", "ReferenciaId" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_PasswordResetTokens_Destino_ReferenciaId",
                table: "PasswordResetTokens");

            migrationBuilder.DropColumn(
                name: "Destino",
                table: "PasswordResetTokens");

            migrationBuilder.DropColumn(
                name: "ReferenciaId",
                table: "PasswordResetTokens");

            migrationBuilder.DropColumn(
                name: "Tentativas",
                table: "PasswordResetTokens");
        }
    }
}
