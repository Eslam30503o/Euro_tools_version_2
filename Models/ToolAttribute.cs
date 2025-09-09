// Models/ToolAttribute.cs
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace WarehouseApp.Models
{
    public class ToolAttribute
    {
        [Key, ForeignKey("Item")]
        public int ItemID { get; set; }  // نفس مفتاح الـ Item

        public decimal? Diameter { get; set; }     // Φ
        public decimal? Radius { get; set; }       // R
        public decimal? Length { get; set; }       // L
        public decimal? Hardness { get; set; }     // H
        public decimal? Pitch { get; set; }        // P (Thread)
        public string MaterialType { get; set; }   // Reamer: مثل Carbide
        public string LocalOrImported { get; set; }  // I or O

        // Navigation property
        public Item Item { get; set; }
    }
}
