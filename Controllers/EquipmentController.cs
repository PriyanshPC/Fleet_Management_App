using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Fleet_Management_App.Controllers
{
    // Controller for managing equipment-related views and actions
    [Authorize] // Restricts access to authenticated users
    public class EquipmentController : Controller
    {
        // Displays the equipment list page
        // Currently, the list is populated via static JavaScript data
        public IActionResult List() => View();

        // Displays details for a specific equipment asset
        // Accepts an asset ID (e.g., "VEH-001") and passes it to the view
        public IActionResult Details(string id)
        {
            ViewBag.AssetId = id ?? "VEH-001"; // Default to "VEH-001" if no ID is provided
            return View();
        }
    }
}