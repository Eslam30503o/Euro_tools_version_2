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
using Microsoft.EntityFrameworkCore;
using ClosedXML.Excel; // ✅ مهم تضيف دي
using Microsoft.AspNetCore.Authorization;

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
        [HttpGet]
        public IActionResult Index()
        {
            var model = new AddItemViewModel
            {
                Categories = _context.Categories.ToList(),
                SubCategories = _context.SubCategories.ToList()
            };

            return View(model);
        }

        [HttpGet]
        public JsonResult GetSubCategories(int categoryId)
        {
            var subCategories = _context.SubCategories
                .Where(s => s.CategoryID == categoryId)
                .Select(s => new
                {
                    subCategoryID = s.SubCategoryID,
                    subCategoryName = s.SubCategoryName,
                    subCategoryCode = s.SubCategoryCode // ← أضف الكود هنا
                })
                .ToList();

            return Json(subCategories);
        }
        [HttpGet]
        public IActionResult Create()
        {
            var model = new AddItemViewModel
            {
                Categories = _context.Categories.ToList(),
                SubCategories = _context.SubCategories.ToList()
            };
            return View(model);
        }

        // POST: AddItem
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Create(AddItemViewModel model)
        {
            // إزالة الربط الغير مفيد من ModelState (لو لسه مش شغال)
            ModelState.Remove("Item.ToolAttribute");
            if (_context.Items.Any(i => i.ItemCode == model.Item.ItemCode))
            {
                ModelState.AddModelError("Item.ItemCode", "هذا الكود مستخدم بالفعل. الرجاء اختيار كود مختلف.");
                // إعادة تعبئة التصنيفات في حال فشل الحفظ
                model.Categories = await _context.Categories.ToListAsync();
                model.SubCategories = await _context.SubCategories.ToListAsync();
                return View(model);
            }


            if (!ModelState.IsValid)
            {
                model.Categories = _context.Categories.ToList();
                model.SubCategories = _context.SubCategories.ToList();
                return View(model);
            }

            // حفظ Item
            _context.Items.Add(model.Item);
            await _context.SaveChangesAsync();

            // حفظ ToolAttribute بعد الحصول على ItemID
            model.ToolAttribute.ItemID = model.Item.ItemID;

            // ✅ لا تضع ToolAttrID يدويًا إطلاقًا

            _context.ToolAttributes.Add(model.ToolAttribute);
            await _context.SaveChangesAsync();

            TempData["SuccessMessage"] = "تمت إضافة المنتج بنجاح!";
            return RedirectToAction("Index", "Items");
        }

        // GET: AddItem/Import
        [HttpGet]
        public IActionResult Import()
        {
            return View();
        }

        public async Task<IActionResult> LowStockItems()
        {
            var lowStockItems = await _context.Items
                .Include(i => i.Category)
                .Where(i => i.CurrentStock <= i.ReorderLevel)
                .ToListAsync();

            return View(lowStockItems);
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
