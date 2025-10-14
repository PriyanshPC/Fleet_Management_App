using Microsoft.AspNetCore.Mvc;

namespace Fleet_Management_App.Controllers
{
    public class EquipmentController : Controller
    {
        public IActionResult Index()
        {
            return View();
        }
    }
}
