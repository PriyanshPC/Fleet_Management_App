using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Fleet_Management_App.Controllers
{
    // Restricts access to authenticated users for tracking features
    [Authorize]
    public class TrackingController : Controller
    {
        /// <summary>
        /// Handles requests to the tracking index page.
        /// Returns the default view for tracking operations.
        /// </summary>
        /// <returns>The Index view for tracking.</returns>
        public IActionResult Index() => View();
    }
}
