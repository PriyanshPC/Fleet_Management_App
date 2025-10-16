using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Fleet_Management_App.Controllers
{
    [Authorize]
    public class TrackingController : Controller
    {
        public IActionResult Index() => View();
    }
}
