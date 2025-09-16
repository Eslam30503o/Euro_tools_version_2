// ViewModels/AddItemViewModel.cs
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using WarehouseApp.Models;

namespace WarehouseApp.Models
{
    public class AddItemViewModel
    {
        public Item Item { get; set; } = new Item();
        public ToolAttribute ToolAttribute { get; set; } = new ToolAttribute();
        public IEnumerable<Category> Categories { get; set; } = new List<Category>();
        public IEnumerable<SubCategory> SubCategories { get; set; } = new List<SubCategory>();
    }

}
