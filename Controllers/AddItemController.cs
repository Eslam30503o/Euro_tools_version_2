using Microsoft.AspNetCore.Mvc;
using WarehouseApp.Data;
using WarehouseApp.Models;
using System.IO;
using System.Threading.Tasks;
using System.Collections.Generic;
using System.Linq;
using CsvHelper;
using System.Globalization;
using Microsoft.AspNetCore.Http;
using ClosedXML.Excel; // ✅ مهم تضيف دي

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

        // GET: AddItem/Import
        [HttpGet]
        public IActionResult Import()
        {
            return View();
        }

        // POST: AddItem/Import (CSV + Excel)
        [HttpPost]
        public async Task<IActionResult> Import(IFormFile file)
        {
            if (file != null && file.Length > 0)
            {
                var extension = Path.GetExtension(file.FileName).ToLower();

                if (extension == ".csv")
                {
                    using var reader = new StreamReader(file.OpenReadStream());
                    using var csv = new CsvReader(reader, CultureInfo.InvariantCulture);

                    var records = csv.GetRecords<dynamic>().ToList();
                    var items = new List<Item>();

                    foreach (var record in records)
                    {
                        string itemCode = record.ItemCode;
                        string itemName = record.ItemName;
                        string categoryName = record.CategoryName; // عمود التصنيف في CSV

                        var category = _context.Categories
                            .FirstOrDefault(c => c.CategoryName == categoryName);

                        if (category != null)
                        {
                            items.Add(new Item
                            {
                                ItemCode = itemCode,
                                ItemName = itemName,
                                CategoryID = category.CategoryID
                            });
                        }
                    }

                    _context.Items.AddRange(items);
                }
                else if (extension == ".xlsx" || extension == ".xls")
                {
                    try
                    {
                        using var stream = new MemoryStream();
                        await file.CopyToAsync(stream);

                        stream.Position = 0; // مهم علشان نقرأ الملف من أوله

                        using var workbook = new ClosedXML.Excel.XLWorkbook(stream);
                        var worksheet = workbook.Worksheets.First();
                        var rows = worksheet.RangeUsed().RowsUsed().Skip(1); // تخطي الهيدر

                        var items = new List<Item>();
                        foreach (var row in rows)
                        {
                            var categoryName = row.Cell(3).GetString();
                            var category = _context.Categories.FirstOrDefault(c => c.CategoryName == categoryName);

                            if (category == null)
                            {
                                category = new Category { CategoryName = categoryName };
                                _context.Categories.Add(category);
                                await _context.SaveChangesAsync();
                            }

                            var item = new Item
                            {
                                ItemCode = row.Cell(1).GetString(),
                                ItemName = row.Cell(2).GetString(),
                                CategoryID = category.CategoryID,
                                Description = row.Cell(4).GetString(),
                                ReorderLevel = int.TryParse(row.Cell(5).GetString(), out int reorderLevel) ? reorderLevel : 0,
                                CurrentStock = int.TryParse(row.Cell(6).GetString(), out int currentStock) ? currentStock : 0
                            };
                            items.Add(item);
                        }

                        _context.Items.AddRange(items);
                    }
                    catch (Exception ex)
                    {
                        ModelState.AddModelError("", $"خطأ أثناء قراءة ملف Excel: {ex.Message}");
                        return View("Import");
                    }
                }



                await _context.SaveChangesAsync();
            }

            return RedirectToAction("Index", "Items");
        }

    }
}
