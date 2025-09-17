using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace WarehouseApp.Migrations
{
    /// <inheritdoc />
    public partial class FixToolAttributeColumnNames : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.RenameColumn(
                name: "MaterialType",
                table: "ToolAttributes",
                newName: "Material");

            migrationBuilder.RenameColumn(
                name: "LocalOrImported",
                table: "ToolAttributes",
                newName: "Source");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.RenameColumn(
                name: "Source",
                table: "ToolAttributes",
                newName: "LocalOrImported");

            migrationBuilder.RenameColumn(
                name: "Material",
                table: "ToolAttributes",
                newName: "MaterialType");
        }
    }
}
