using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using WarehouseApp.Models;

namespace WarehouseApp.Models
{ 
public class ToolCreateViewModel
{
    // من جدول Items
    public string ItemName { get; set; }
    public string? Description { get; set; }
    public int CategoryID { get; set; }
    public int? SubCategoryID { get; set; }
    public string Unit { get; set; }
    public int ReorderLevel { get; set; }
    public int CurrentStock { get; set; }
    //public string? Type { get; set; }
        // من جدول ToolAttributes
        public decimal? Diameter { get; set; }
    public decimal? Radius { get; set; }
    public decimal? Length { get; set; }
    public decimal? Hardness { get; set; }
    public decimal? Pitch { get; set; }
    public string? Material { get; set; }
    public string? Source { get; set; }

    // Lists for dropdowns
    public IEnumerable<Category> Categories { get; set; }
    public IEnumerable<SubCategory> SubCategories { get; set; }
}
}
