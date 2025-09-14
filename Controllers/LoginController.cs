using Microsoft.AspNetCore.Mvc;
using WarehouseApp.Data;
using WarehouseApp.Models;
using System.Linq;
using System.Security.Claims;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;

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

        public async Task<IActionResult> Logout()
        {
            await HttpContext.SignOutAsync("WarehouseAuth");
            TempData["LogoutMessage"] = "تم تسجيل الخروج بنجاح.";
            return RedirectToAction("Index", "Login");
        }

        public IActionResult AccessDenied()
        {
            TempData["PermissionDenied"] = "❌ لا تملك صلاحية الوصول إلى هذه الصفحة.";
            return View();
        }


        [HttpPost]
        public async Task<IActionResult> Index(string username, string password, string role)

        {
            var user = _context.Users.FirstOrDefault(u =>
                u.Username == username && u.Password == password && u.Role == role);

            if (user != null)
            {
                var claims = new List<Claim>
                {
                    new Claim(ClaimTypes.NameIdentifier, user.UserID.ToString()),
                    new Claim(ClaimTypes.Name, user.Username),
                    new Claim(ClaimTypes.Role, user.Role)
                };

                var claimsIdentity = new ClaimsIdentity(claims, "WarehouseAuth");

                // تسجيل الدخول (إنشاء كوكي)
                await HttpContext.SignInAsync("WarehouseAuth", new ClaimsPrincipal(claimsIdentity));

                return RedirectToAction("Index", "Home");
            }

            // ❌ بيانات خاطئة
            ViewBag.Error = "اسم المستخدم أو كلمة السر أو الوظيفة غير صحيحة";
            return View();
        }
    }
}
