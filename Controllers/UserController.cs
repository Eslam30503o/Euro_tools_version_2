using Microsoft.AspNetCore.Mvc;
using WarehouseApp.Data;
using WarehouseApp.Models;
using System.Linq;

namespace WarehouseApp.Controllers
{
	public class UserController : Controller
	{
		private readonly WarehouseDbContext _context;

		public UserController(WarehouseDbContext context)
		{
			_context = context;
		}

		// GET: User/AddUser
		public IActionResult AddUser()
		{
			return View();
		}

		// POST: User/AddUser
		[HttpPost]
		public IActionResult AddUser(User user)
		{
			if (ModelState.IsValid)
			{
				_context.Users.Add(user);
				_context.SaveChanges();
				TempData["Success"] = "تم إضافة المستخدم بنجاح!";
				return RedirectToAction("Index", "Home"); // بعد الإضافة يرجع لصفحة الهوم
			}

			return View(user);
		}
	}
}
