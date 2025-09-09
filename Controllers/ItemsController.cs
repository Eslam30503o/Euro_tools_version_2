using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using WarehouseApp.Data;
using WarehouseApp.Models;

namespace WarehouseApp.Controllers
{
    public class ItemsController : Controller
    {
        private readonly WarehouseDbContext _context;

        public ItemsController(WarehouseDbContext context)
        {
            _context = context;
        }

        public async Task<IActionResult> Index()
        {
            var items = await _context.Items
                .Include(i => i.Category)
                .ToListAsync();

            return View(items);
        }
    }
}
