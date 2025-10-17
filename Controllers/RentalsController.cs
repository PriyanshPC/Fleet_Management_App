using Fleet_Management_App.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Fleet_Management_App.Controllers
{
    // Ensures only authenticated users can access rental management features
    [Authorize]
    public class RentalsController : Controller
    {
        /// <summary>
        /// Static in-memory list of rental records used for demonstration purposes.
        /// Each RentalListItem represents a single rental transaction.
        /// </summary>
        private static readonly List<RentalListItem> Rentals = new()
        {
            new(){ Id="R-1035", Client="Starlight Media",  Category="Cameras",  Items="FX6 Camera, Tripod",         Out=new(2025,10,12), Due=new(2025,10,18), Status="On Rent",   Total=420.00m },
            new(){ Id="R-1034", Client="MediaOne",         Category="Cameras",  Items="FX3 Kit",                    Out=new(2025,10,09), Due=new(2025,10,11), Status="Cancelled", Total=0.00m   },
            new(){ Id="R-1033", Client="Vision Crew",      Category="Drones",   Items="Drone Pro X",                Out=new(2025,10,02), Due=new(2025,10,10), Status="Returned",  Total=680.00m },
            new(){ Id="R-1032", Client="Filmhouse",        Category="Cameras",  Items="RED Komodo",                 Out=new(2025,10,05), Due=new(2025,10,16), Status="Overdue",   Total=950.00m },
            new(){ Id="R-1031", Client="Ghost Diagnostics",Category="Vehicles", Items="Transit Van, 2× Drones",     Out=new(2025,10,10), Due=new(2025,10,20), Status="On Rent",   Total=1200.00m},
            new(){ Id="R-1030", Client="Nova Events",      Category="Mics",     Items="4× Lavalier Mics",           Out=new(2025,10,13), Due=new(2025,10,15), Status="Due Soon",  Total=160.00m },
            new(){ Id="R-1029", Client="Northline Labs",   Category="PPE",      Items="5× Hazmat Suits",            Out=new(2025,10,08), Due=new(2025,10,14), Status="Scheduled", Total=300.00m },
            new(){ Id="R-1028", Client="BuildRight",       Category="Tools",    Items="Thermal Imager",             Out=new(2025,10,01), Due=new(2025,10,12), Status="Returned",  Total=210.00m }
        };

        /// <summary>
        /// Displays a list of all rental records.
        /// Passes the Rentals collection to the view for rendering.
        /// </summary>
        /// <returns>View displaying all rentals.</returns>
        public IActionResult List()
        {
            return View(Rentals);
        }

        /// <summary>
        /// Shows details for a specific rental based on its ID.
        /// Returns 404 if the ID is missing or not found.
        /// </summary>
        /// <param name="id">Rental identifier.</param>
        /// <returns>View with rental details, or NotFound if not found.</returns>
        public IActionResult Details(string id)
        {
            if (string.IsNullOrWhiteSpace(id)) return NotFound();
            var rental = Rentals.FirstOrDefault(r => r.Id.Equals(id, StringComparison.OrdinalIgnoreCase));
            if (rental == null) return NotFound();

            return View(rental);
        }

        /// <summary>
        /// Displays a form for creating a new rental record.
        /// </summary>
        /// <returns>View for new rental creation.</returns>
        public IActionResult New() => View();

        /// <summary>
        /// Displays the payment page for a specific rental.
        /// </summary>
        /// <param name="id">Rental identifier.</param>
        /// <returns>View for processing payment.</returns>
        public IActionResult Payment(string id) => View();
    }
}