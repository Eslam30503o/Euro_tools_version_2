using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using WarehouseApp.Data; // ← حسب مسار ملف DbContext
using WarehouseApp.Models; // ← لو فيه Models تستخدمها في الاستعلام

public class TransactionController : Controller
{
    private readonly WarehouseDbContext _context;

    public TransactionController(WarehouseDbContext context)
    {
        _context = context;
    }

    public async Task<IActionResult> Index(string actionType, DateTime? fromDate, DateTime? toDate, string search)
    {
        var transactions = _context.Transactions
            .Include(t => t.Item)
            .Include(t => t.User)
            .AsQueryable();

        // 🔍 فلترة حسب نوع العملية
        if (!string.IsNullOrEmpty(actionType))
        {
            transactions = transactions.Where(t => t.Action == actionType);
        }

        // 📅 فلترة بالتاريخ
        if (fromDate.HasValue)
        {
            transactions = transactions.Where(t => t.Timestamp >= fromDate.Value);
        }

        if (toDate.HasValue)
        {
            transactions = transactions.Where(t => t.Timestamp <= toDate.Value);
        }

        // 🔎 بحث بالاسم أو الكود
        if (!string.IsNullOrEmpty(search))
        {
            transactions = transactions.Where(t =>
                t.Item.ItemName.Contains(search) || t.Item.ItemCode.Contains(search));
        }

        var result = await transactions.OrderByDescending(t => t.Timestamp).ToListAsync();
        return View(result);
    }

}
