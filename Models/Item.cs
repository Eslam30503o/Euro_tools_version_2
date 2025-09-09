// Models/Item.cs
using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace WarehouseApp.Models
{
    public class Item
    {
        public int ItemID { get; set; }

        [Required]
        public string ItemCode { get; set; }  // الباركود (الفريد)

        [Required]
        public string ItemName { get; set; }

        public string Description { get; set; }

        public int CategoryID { get; set; }

        public string Unit { get; set; }

        public int ReorderLevel { get; set; } = 0;

        public int CurrentStock { get; set; } = 0;

        public DateTime CreatedAt { get; set; } = DateTime.Now;
        
        public string? BarCode1 { get; set; }

        // علاقات
        public Category? Category { get; set; }
        public ToolAttribute? ToolAttribute { get; set; }
    }
}
