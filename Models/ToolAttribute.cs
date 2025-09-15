using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace WarehouseApp.Models
{
    public class ToolAttribute
    {
        [Key]  // هذا هو المفتاح الأساسي
        [ForeignKey("Item")]  // وهو أيضًا مفتاح خارجي يشير إلى Item
        public int ItemID { get; set; }

        [Column(TypeName = "decimal(10,2)")]
        public decimal? Diameter { get; set; }

        [Column(TypeName = "decimal(10,2)")]
        public decimal? Radius { get; set; }

        [Column(TypeName = "decimal(10,2)")]
        public decimal? Length { get; set; }

        [Column(TypeName = "decimal(10,2)")]
        public decimal? Hardness { get; set; }

        [Column(TypeName = "decimal(10,2)")]
        public decimal? Pitch { get; set; }

        public string MaterialType { get; set; }

        public string LocalOrImported { get; set; }

        public Item Item { get; set; }  // Navigation property
    }
}
