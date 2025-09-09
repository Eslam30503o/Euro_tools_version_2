using Microsoft.AspNetCore.Mvc;
using WarehouseApp.Data;
using WarehouseApp.Models;
using System.Linq;

namespace WarehouseApp.Controllers
{
    public class LoginController : Controller
    {
        private readonly WarehouseDbContext _context;

        public LoginController(WarehouseDbContext context)
        {
            _context = context;
        }

        [HttpGet]
        public IActionResult Index()
        {
            return View();
        }

        [HttpPost]
        public IActionResult Index(string username, string password, string role)
        {
            var user = _context.Users.FirstOrDefault(u =>
                u.Username == username && u.Password == password && u.Role == role);

            if (user != null)
            {
                // ✅ تسجيل الدخول الناجح
                TempData["Success"] = "تم تسجيل الدخول بنجاح";
                return RedirectToAction("Index", "Home");
            }

            // ❌ بيانات خاطئة
            ViewBag.Error = "اسم المستخدم أو كلمة السر أو الوظيفة غير صحيحة";
            return View();
        }
    }
}
