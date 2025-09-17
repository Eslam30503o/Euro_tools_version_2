using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace WarehouseApp.Models
{
    public class SubCategory
    {
        public int SubCategoryID { get; set; }

        [Required]
        public string SubCategoryName { get; set; }
        public string? SubCategoryCode { get; set; }
        // 🔁 علاقة مع التصنيف الرئيسي
        public int CategoryID { get; set; }
        public Category Category { get; set; }

        // 🔁 علاقة مع الأدوات (Items)
        public ICollection<Item> Items { get; set; }
    }
}
