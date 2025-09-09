using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using WarehouseApp.Data;
using WarehouseApp.Models;

namespace WarehouseApp.Controllers
{
    public class ToolsController : Controller
    {
        private readonly WarehouseDbContext _context;

        public ToolsController(WarehouseDbContext context)
        {
            _context = context;
        }

        // GET: Tools
        public async Task<IActionResult> Index()
        {
            var tools = await _context.Items
                .Include(i => i.ToolAttribute)
                .Include(i => i.Category)
                .ToListAsync();
            return View(tools);
        }
    }
}
