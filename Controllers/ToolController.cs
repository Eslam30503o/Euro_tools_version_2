using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using WarehouseApp.Data;
using WarehouseApp.Models;
using System.Threading.Tasks;
using System.Linq;
using Microsoft.AspNetCore.Authorization;

namespace WarehouseApp.Controllers
{
    [Authorize(Roles = "Manager,Admin,Supervisor")]
    public class ToolController : Controller
    {
        private readonly WarehouseDbContext _context;

        public ToolController(WarehouseDbContext context)
        {
            _context = context;
        }
        [HttpGet]
        public JsonResult GetSubCategories(int categoryId)
        {
            var subCategories = _context.SubCategories
                .Where(sc => sc.CategoryID == categoryId)
                .Select(sc => new { sc.SubCategoryID, sc.SubCategoryName })
                .ToList();

            return Json(subCategories);
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

        // GET: Tools/Details/5
        public async Task<IActionResult> Details(int? id)
        {
            if (id == null) return NotFound();

            var tool = await _context.Items
                .Include(i => i.ToolAttribute)
                .Include(i => i.Category)
                .FirstOrDefaultAsync(m => m.ItemID == id);

            if (tool == null) return NotFound();

            return View(tool);
        }

        // GET: Tools/Create
        public IActionResult Create()
        {
            var model = new ToolCreateViewModel
            {
                Categories = _context.Categories.ToList(),
                SubCategories = _context.SubCategories.ToList()
            };
            return View(model);
        }


        // POST: Tools/Create
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Create(ToolCreateViewModel model)
        {
            if (!ModelState.IsValid)
            {
                model.Categories = _context.Categories.ToList();
                model.SubCategories = _context.SubCategories.ToList();
                return View(model);
            }

            // 1. Add item
            var item = new Item
            {
                ItemName = model.ItemName,
                Description = model.Description,
                CategoryID = model.CategoryID,
                SubCategoryID = model.SubCategoryID,
                Unit = model.Unit,
                ReorderLevel = model.ReorderLevel,
                CurrentStock = model.CurrentStock
            };

            _context.Items.Add(item);
            await _context.SaveChangesAsync();

            // 2. Add tool attributes
            var toolAttr = new ToolAttribute
            {
                ItemID = item.ItemID,
                Diameter = model.Diameter,
                Radius = model.Radius,
                Length = model.Length,
                Hardness = model.Hardness,
                Pitch = model.Pitch,
                MaterialType = model.MaterialType,
                LocalOrImported = model.LocalOrImported
            };

            _context.ToolAttributes.Add(toolAttr);
            await _context.SaveChangesAsync();

            return RedirectToAction(nameof(Index));
        }


        // GET: Tools/Edit/5
        public async Task<IActionResult> Edit(int? id)
        {
            if (id == null) return NotFound();

            var item = await _context.Items.FindAsync(id);
            if (item == null) return NotFound();

            return View(item);
        }

        // POST: Tools/Edit/5
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Edit(int id, Item item)
        {
            if (id != item.ItemID) return NotFound();

            if (ModelState.IsValid)
            {
                try
                {
                    _context.Update(item);
                    await _context.SaveChangesAsync();
                }
                catch (DbUpdateConcurrencyException)
                {
                    if (!_context.Items.Any(e => e.ItemID == id))
                        return NotFound();
                    else
                        throw;
                }
                return RedirectToAction(nameof(Index));
            }
            return View(item);
        }

        // GET: Tools/Delete/5
        public async Task<IActionResult> Delete(int? id)
        {
            if (id == null) return NotFound();

            var tool = await _context.Items
                .FirstOrDefaultAsync(m => m.ItemID == id);

            if (tool == null) return NotFound();

            return View(tool);
        }

        // POST: Tools/Delete/5
        [HttpPost, ActionName("Delete")]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> DeleteConfirmed(int id)
        {
            var tool = await _context.Items.FindAsync(id);
            if (tool != null)
            {
                _context.Items.Remove(tool);
                await _context.SaveChangesAsync();
            }
            return RedirectToAction(nameof(Index));
        }
    }
}
