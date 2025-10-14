using Microsoft.AspNetCore.Mvc;

namespace Fleet_Management_App.Controllers
{
    public class MaintenanceController : Controller
    {
        public IActionResult Index()
        {
            return View();
        }
    }
}
