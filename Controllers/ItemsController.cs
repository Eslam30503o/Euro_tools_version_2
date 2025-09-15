using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using WarehouseApp.Data;
using WarehouseApp.Models;
using System.IO;
using System.Threading.Tasks;
using System.Collections.Generic;
using System.Linq;
using WarehouseApp.Models;
using CsvHelper;
using System.Globalization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Authorization;

namespace WarehouseApp.Controllers
{
    [Authorize(Roles = "Manager,Admin")]
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
    .Include(i => i.SubCategory)     // اضيف SubCategory
    .Include(i => i.ToolAttribute)   // لو عايز تعرض بيانات الأدوات
    .ToListAsync();

            return View(items);
        }
        
    }
}
