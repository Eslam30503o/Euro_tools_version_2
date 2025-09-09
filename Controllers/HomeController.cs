using Microsoft.AspNetCore.Mvc;

namespace WarehouseApp.Controllers
{
    public class HomeController : Controller
    {
        public IActionResult Index()
        {
            return View();
        }
    }
}
