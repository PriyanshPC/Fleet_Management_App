using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Fleet_Management_App.Controllers
{
    [Authorize]
    public class EquipmentController : Controller
    {
        public IActionResult List() => View();    // Uses static JS list for now
        public IActionResult Details(string id)   // Pass asset id (like VEH-001)
        {
            ViewBag.AssetId = id ?? "VEH-001";
            return View();
        }
    }
}
