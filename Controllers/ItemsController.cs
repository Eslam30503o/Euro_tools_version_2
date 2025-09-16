// Controllers/ItemsController.cs
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

        // GET: Items/Create
        public IActionResult Create()
        {
            var model = new AddItemViewModel
            {
                Categories = _context.Categories.ToList(),
                SubCategories = _context.SubCategories.ToList()
            };
            return View(model);
        }

        // POST: Items/Create
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Create(AddItemViewModel model)
        {
            if (!ModelState.IsValid)
            {
                model.Categories = _context.Categories.ToList();
                model.SubCategories = _context.SubCategories.ToList();
                return View(model);
            }

            _context.Items.Add(model.Item);
            await _context.SaveChangesAsync();

            model.ToolAttribute.ItemID = model.Item.ItemID;
            _context.ToolAttributes.Add(model.ToolAttribute);
            await _context.SaveChangesAsync();

            TempData["SuccessMessage"] = "تم إضافة المنتج بنجاح";
            return RedirectToAction(nameof(Index));
        }

        // Index (للتجربة)
        public IActionResult Index()
        {
            var items = _context.Items.Include(i => i.ToolAttribute).ToList();
            return View(items);
        }
    }
}
