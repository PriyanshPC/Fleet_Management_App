// Controllers/DashboardController.cs
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Fleet_Management_App.Controllers
{
    [Authorize]                    // <— add
    public class DashboardController : Controller
    {
        public IActionResult Index() => View();
    }
}
