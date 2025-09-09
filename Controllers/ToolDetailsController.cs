using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using WarehouseApp.Data;
using WarehouseApp.Models;

namespace WarehouseApp.Controllers
{
    public class ToolDetailsController : Controller
    {
        private readonly WarehouseDbContext _context;

        public ToolDetailsController(WarehouseDbContext context)
        {
            _context = context;
        }

        // GET: ToolDetails/5
        public async Task<IActionResult> Index(int id)
        {
            var tool = await _context.Items
                .Include(i => i.ToolAttribute)
                .Include(i => i.Category)
                .FirstOrDefaultAsync(i => i.ItemID == id);

            if (tool == null)
            {
                return NotFound();
            }

            return View(tool);
        }
        public async Task<IActionResult> All()
        {
            var tools = await _context.Items
                .Include(i => i.ToolAttribute)
                .Include(i => i.Category)
                .ToListAsync();

            return View(tools); // هيبقى في Views/ToolDetails/All.cshtml
        }
    }

    }
