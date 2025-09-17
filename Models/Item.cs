// Models/Item.cs
using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using WarehouseApp.Models;

namespace WarehouseApp.Models
{
    public class Item
    {
        public int ItemID { get; set; }

        [Required(ErrorMessage = "يجب كتاب الكود")]
        public string ItemCode { get; set; }  // الباركود (الفريد)

        [Required(ErrorMessage = "يجب كتاب اسم المنتج")]
        public string ItemName { get; set; }

        [Required(ErrorMessage = "يجب كتاب وصف المنتج")]

        public string Description { get; set; }

        [Required(ErrorMessage = "يجب تحديد الفئة")]
        public int CategoryID { get; set; }
        
        [Required(ErrorMessage = "يجب تحديد الوحدة")]       
        public string Unit { get; set; }
        
        [Required(ErrorMessage = "يجب تحديد اقل قيمة")]
        public int ReorderLevel { get; set; } = 0;
        
        [Required(ErrorMessage = "يجب تحديد العدد الفعلي")]
        public int CurrentStock { get; set; } = 0;

        public DateTime CreatedAt { get; set; } = DateTime.Now;
        
        public string? BarCode1 { get; set; }
        
        //[Required(ErrorMessage = "يجب تحديد النوع")]
        public string? Type { get; set; }

        //[Required(ErrorMessage = "يجب تحديد الصنف")]
        public int? SubCategoryID { get; set; }
        
        [ForeignKey("SubCategoryID")]
        public SubCategory? SubCategory { get; set; }

        // علاقات
        public Category? Category { get; set; }
        public ToolAttribute? ToolAttribute { get; set; }
    }
}
