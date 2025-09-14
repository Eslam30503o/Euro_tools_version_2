using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Linq;
using WarehouseApp.Data;
using WarehouseApp.Models;
using Microsoft.AspNetCore.Authorization;

namespace WarehouseApp.Controllers
{
    [Authorize(Roles = "Manager,Admin")]
    public class ReportsController : Controller
    {
        private readonly WarehouseDbContext _context;

        public ReportsController(WarehouseDbContext context)
        {
            _context = context;
        }

        public IActionResult Index()
        {
            // جلب البيانات الأساسية
            var items = _context.Items
                .Include(i => i.Category)
                .ToList();

            var transactions = _context.Transactions
                .Include(t => t.Item)
                .Include(t => t.User)
                .OrderByDescending(t => t.Timestamp)   // حسب اسم الحقل عندك قد يكون Date أو Timestamp
                .Take(200)
                .ToList();

            var lowStockItems = items.Where(i => i.CurrentStock <= i.ReorderLevel).ToList();

            var itemsByCategory = _context.Items
                .Include(i => i.Category)
                .AsEnumerable()
                .GroupBy(i => i.Category?.CategoryName ?? "Uncategorized")
                .Select(g => new ItemsByCategoryViewModel
                {
                    CategoryName = g.Key,
                    ItemCount = g.Count()
                })
                .ToList();

            var model = new DashboardViewModel
            {
                TotalItems = items.Count,
                TotalStock = items.Sum(i => i.CurrentStock),
                Transactions = transactions,
                Items = items,
                LowStockItems = lowStockItems,
                ItemsByCategory = itemsByCategory
            };

            return View(model);
        }
    }
}
