using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Fleet_Management_App.Controllers
{
    [Authorize]
    public class EquipmentController : Controller
    {
        public IActionResult List() => View();

        [HttpGet("equipment/{id:int}")]
        public IActionResult Details(int id)
        {
            ViewBag.Id = id;
            return View();
        }
    }
}
