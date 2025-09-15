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
    [Authorize(Roles = "Manager,Admin")]
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

        [HttpGet("AddItem/GetSubCategories")]
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

        // POST: AddItem
        [HttpPost]
        [ValidateAntiForgeryToken] // ✅ مهم جداً للأمان
        public async Task<IActionResult> Index(AddItemViewModel model)
        {
            Console.WriteLine("Length = " + model.Item.ToolAttribute?.Length);

            // 1. التحقق من صلاحية البيانات المدخلة في النموذج (Model)
            if (!ModelState.IsValid)
            {
                // لو النموذج غير صالح، أرجع لنفس الـ View مع البيانات المدخلة
                // ولا تنسى إعادة تعبئة القوائم المنسدلة
                model.Categories = await _context.Categories.ToListAsync();
                model.SubCategories = await _context.SubCategories.ToListAsync();
                return View(model);
            }

            // 2. استخدم Transaction لضمان حفظ كل شيء أو لا شيء
            using (var transaction = await _context.Database.BeginTransactionAsync())
            {
                try
                {
                    // 3. أضف الـ Item للـ context
                    _context.Items.Add(model.Item);

                    // 4. لا تستخدم SaveChanges() هنا
                    // انتظر حتى يتم إضافة كل شيء ثم احفظ الكل معًا
                    await _context.SaveChangesAsync();
                    // بعد الـ SaveChanges() الأول، الـ ItemID هيتولد تلقائيًا

                    // 5. إذا كان هناك ToolAttribute، أضفه واربطه
                    if (model.Item.ToolAttribute != null)
                    {
                        model.Item.ToolAttribute = model.ToolAttribute; // ✅ اربطها هنا
                        model.Item.ToolAttribute.ItemID = model.Item.ItemID;
                        _context.ToolAttributes.Add(model.Item.ToolAttribute);
                    }


                    await _context.SaveChangesAsync();

                    // 8. لو كل شيء تمام، أكمل الـ Transaction
                    await transaction.CommitAsync();

                    TempData["Success"] = "تمت إضافة العنصر بنجاح.";
                    return RedirectToAction("Index");
                }
                catch (DbUpdateException ex)
                {
                    // لو فيه خطأ في الحفظ في قاعدة البيانات
                    // (زي محاولة إضافة ItemCode موجود قبل كده)
                    await transaction.RollbackAsync();
                    ModelState.AddModelError("", "خطأ أثناء حفظ البيانات: تأكد من أن رمز العنصر (Item Code) غير مكرر.");
                }
                catch (Exception ex)
                {
                    // لو فيه أي خطأ تاني
                    await transaction.RollbackAsync();
                    ModelState.AddModelError("", "حدث خطأ غير متوقع: " + ex.Message);
                }
            }

            // لو حصل أي خطأ في الـ try-catch block،
            // أعد عرض الصفحة مع رسائل الخطأ.
            model.Categories = await _context.Categories.ToListAsync();
            model.SubCategories = await _context.SubCategories.ToListAsync();
            return View(model);
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
