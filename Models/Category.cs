// Models/Category.cs
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace WarehouseApp.Models
{
    public class Category
    {
        public int CategoryID { get; set; }
        public string CategoryName { get; set; } = string.Empty;
    }
}
