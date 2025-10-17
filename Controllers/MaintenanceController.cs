using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Fleet_Management_App.Controllers
{
    // Restricts access to authenticated users only
    [Authorize]
    public class MaintenanceController : Controller
    {
        /// <summary>
        /// Handles requests to the Maintenance index page.
        /// Returns the default view for maintenance operations.
        /// </summary>
        /// <returns>The Index view for maintenance.</returns>
        public IActionResult Index() => View();
    }
}
