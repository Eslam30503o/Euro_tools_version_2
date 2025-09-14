using System;
using System.Collections.Generic;

namespace WarehouseApp.Models
{
    public class DashboardViewModel
    {
        public int TotalItems { get; set; }
        public int TotalStock { get; set; }

        public List<Transaction> Transactions { get; set; } = new List<Transaction>();
        public List<Item> Items { get; set; } = new List<Item>();
        public List<Item> LowStockItems { get; set; } = new List<Item>();

        public List<ItemsByCategoryViewModel> ItemsByCategory { get; set; } = new List<ItemsByCategoryViewModel>();
    }

    public class ItemsByCategoryViewModel
    {
        public string CategoryName { get; set; }
        public int ItemCount { get; set; }
    }
}
