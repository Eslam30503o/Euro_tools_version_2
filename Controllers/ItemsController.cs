// Controllers/ItemsController.cs
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using WarehouseApp.Data;
using WarehouseApp.Models;
using ClosedXML.Excel;

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
        [HttpDelete]
        public IActionResult Delete(string id)
        {
            var item = _context.Items.FirstOrDefault(i => i.ItemCode == id);

            if (item == null)
                return NotFound();

            _context.Items.Remove(item);
            _context.SaveChanges();

            return Ok();
        }

        public IActionResult Details(string id)
        {
            var item = _context.Items
                .Include(i => i.Category)
                .Include(i => i.ToolAttribute)
                .FirstOrDefault(i => i.ItemCode == id);

            if (item == null)
            {
                return NotFound();
            }

            return View(item); // اعمل لها View لاحقًا أو Modal
        }

        // Index (للتجربة)
        public IActionResult Index()
        {
            var items = _context.Items
                .Include(i => i.Category)
                .Include(i => i.ToolAttribute)
                .ToList();

            return View(items);
        }
        public IActionResult ExportToExcel()
        {
            var items = _context.Items.Include(i => i.Category).ToList();

            using (var workbook = new XLWorkbook())
            {
                var worksheet = workbook.Worksheets.Add("Items");
                worksheet.Cell(1, 1).Value = "Item Code";
                worksheet.Cell(1, 2).Value = "Item Name";
                worksheet.Cell(1, 3).Value = "Category";
                worksheet.Cell(1, 4).Value = "Current Stock";

                for (int i = 0; i < items.Count; i++)
                {
                    worksheet.Cell(i + 2, 1).Value = items[i].ItemCode;
                    worksheet.Cell(i + 2, 2).Value = items[i].ItemName;
                    worksheet.Cell(i + 2, 3).Value = items[i].Category?.CategoryName ?? "N/A";
                    worksheet.Cell(i + 2, 4).Value = items[i].CurrentStock;
                }

                using (var stream = new MemoryStream())
                {
                    workbook.SaveAs(stream);
                    var content = stream.ToArray();
                    return File(content,
                        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                        "Items.xlsx");
                }
            }
        }

    }
}
