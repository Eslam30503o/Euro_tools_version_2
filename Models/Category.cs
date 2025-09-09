// Models/Category.cs
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace WarehouseApp.Models
{
    public class Category
    {
        public int CategoryID { get; set; }

        [Required]
        public string CategoryName { get; set; }

        // Navigation property
        public ICollection<Item> Items { get; set; }
    }
}
