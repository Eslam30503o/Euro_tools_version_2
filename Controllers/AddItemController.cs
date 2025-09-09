using Microsoft.AspNetCore.Mvc;
using WarehouseApp.Data;
using WarehouseApp.Models;

namespace WarehouseApp.Controllers
{
    public class AddItemController : Controller
    {
        private readonly WarehouseDbContext _context;

        public AddItemController(WarehouseDbContext context)
        {
            _context = context;
        }

        // GET: AddItem
        public IActionResult Index()
        {
            // تحميل الكاتيجوريز من قاعدة البيانات
            var categories = _context.Categories.ToList();
            ViewBag.Categories = categories;

            return View();
        }

        // POST: AddItem
        [HttpPost]
        public IActionResult Index(Item item)
        {
            if (!ModelState.IsValid)
            {
                ViewBag.Categories = _context.Categories.ToList();

                foreach (var key in ModelState.Keys)
                {
                    var errors = ModelState[key].Errors;
                    foreach (var error in errors)
                    {
                        Console.WriteLine($"Model Error for {key}: {error.ErrorMessage}");
                    }
                }

                return View(item);
            }

            try
            {
                _context.Items.Add(item);
                _context.SaveChanges();

                TempData["Success"] = "Item added successfully!";
                return RedirectToAction("Index");
            }
            catch (Exception ex)
            {
                ModelState.AddModelError("", "Error saving to database: " + ex.Message);
                ViewBag.Categories = _context.Categories.ToList();
                return View(item);
            }
        }

    }
}
