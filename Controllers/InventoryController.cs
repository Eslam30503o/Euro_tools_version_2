using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Rendering;
using Microsoft.EntityFrameworkCore;
using WarehouseApp.Data;
using WarehouseApp.Models;
using System.Linq;
using System.Threading.Tasks;

public class InventoryController : Controller
{
    private readonly WarehouseDbContext _context;

    public InventoryController(WarehouseDbContext context)
    {
        _context = context;
    }

    // هذه الدالة ستتعامل مع كل من الطلبات التي بها بحث والتي بدون بحث
    [HttpGet] // إضافة هذه السمة للتوضيح
    public async Task<IActionResult> Create(string SearchString)
    {
        // حفظ قيمة البحث الحالية
        ViewData["CurrentFilter"] = SearchString;

        // جلب قائمة المنتجات
        var items = from i in _context.Items
                    select i;

        // تطبيق فلتر البحث إذا كانت قيمة البحث موجودة
        if (!string.IsNullOrEmpty(SearchString))
        {
            items = items.Where(s => s.ItemName.Contains(SearchString)
                                   || s.ItemCode.Contains(SearchString));
        }

        // جلب البيانات وإعدادها للعرض
        var itemsWithQuantity = await items.Select(i => new
        {
            ID = i.ItemID,
            Name = $"{i.ItemName} ({i.ItemCode}) - متوفر: {i.CurrentStock}"
        }).ToListAsync();

        ViewBag.Items = new SelectList(itemsWithQuantity, "ID", "Name");

        return View();
    }

    // هذه الدالة ستظل تتعامل مع طلب POST بشكل صحيح
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Create(TransactionViewModel model)
    {
        if (!ModelState.IsValid)
        {
            // عند وجود خطأ، يجب إعادة ملء القائمة بالمنتجات مرة أخرى
            var itemsWithQuantity = await _context.Items.Select(i => new
            {
                ID = i.ItemID,
                Name = $"{i.ItemName} ({i.ItemCode}) - متوفر: {i.CurrentStock}"
            }).ToListAsync();
            ViewBag.Items = new SelectList(itemsWithQuantity, "ID", "Name", model.ItemID);
            return View(model);
        }

        var item = await _context.Items.FindAsync(model.ItemID);
        if (item == null)
            return NotFound();

        // تحديث الكمية في جدول Items
        if (model.Action == "Withdraw")
        {
            if (item.CurrentStock < model.Quantity)
            {
                ModelState.AddModelError("", "لا يوجد كمية كافية في المخزن للسحب");
                var itemsWithQuantity = await _context.Items.Select(i => new
                {
                    ID = i.ItemID,
                    Name = $"{i.ItemName} ({i.ItemCode}) - متوفر: {i.CurrentStock}"
                }).ToListAsync();
                ViewBag.Items = new SelectList(itemsWithQuantity, "ID", "Name", model.ItemID);
                return View(model);
            }
            item.CurrentStock -= model.Quantity;
        }
        else if (model.Action == "Add")
        {
            item.CurrentStock += model.Quantity;
        }

        // إضافة حركة في جدول Transactions
        var transaction = new Transaction
        {
            ItemID = model.ItemID,
            Action = model.Action,
            QuantityChange = model.Action == "Withdraw" ? -model.Quantity : model.Quantity,
            Timestamp = DateTime.Now,
            UserID = 1
        };

        _context.Transactions.Add(transaction);
        _context.Items.Update(item);
        await _context.SaveChangesAsync();

        return RedirectToAction("Index", "Home");
    }
}