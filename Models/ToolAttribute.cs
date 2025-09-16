using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.AspNetCore.Mvc.ModelBinding;

namespace WarehouseApp.Models
{
    public class ToolAttribute
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)] // ✅ تأكيد أن SQL مسؤول عن التوليد
        [BindNever]
        public int ToolAttrID { get; set; } // مفتاح أساسي

        [Required]
        public int ItemID { get; set; } // مفتاح خارجي

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

        public string? Source { get; set; }

        public string? Material { get; set; }

        // Navigation property
        public Item? Item { get; set; }
    }
}
