using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using WarehouseApp.Models;

namespace WarehouseApp.Models
{
    public class AddItemViewModel
    {
        public Item Item { get; set; } = new Item(); // جوه ده فيه ToolAttribute كـ property
        public ToolAttribute ToolAttribute { get; set; } = new ToolAttribute();

        public IEnumerable<Category> Categories { get; set; } = new List<Category>();
        public IEnumerable<SubCategory> SubCategories { get; set; } = new List<SubCategory>();
    }
}