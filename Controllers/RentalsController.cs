using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Fleet_Management_App.Controllers
{
    [Authorize]
    public class RentalsController : Controller
    {
        public IActionResult List() => View();

        [HttpGet("rentals/{id:int}")]
        public IActionResult Details(int id)
        {
            ViewBag.Id = id;
            return View();
        }

        [HttpGet("rentals/new")]
        public IActionResult New() => View();

        [HttpGet("payment")]
        public IActionResult Payment() => View();
    }
}
