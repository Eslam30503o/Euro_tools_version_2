using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using WarehouseApp.Data;
using WarehouseApp.Models;
using System.Threading.Tasks;
using System.Linq;

namespace WarehouseApp.Controllers
{
    public class ToolController : Controller
    {
        private readonly WarehouseDbContext _context;

        public ToolController(WarehouseDbContext context)
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
            return View();
        }

        // POST: Tools/Create
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Create(Item item)
        {
            if (ModelState.IsValid)
            {
                _context.Add(item);
                await _context.SaveChangesAsync();
                return RedirectToAction(nameof(Index));
            }
            return View(item);
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
