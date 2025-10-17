using Fleet_Management_App.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Fleet_Management_App.Controllers
{
    // Ensures only authenticated users can access the dashboard
    [Authorize]
    public class DashboardController : Controller
    {
        // Displays the main dashboard view with key metrics and data
        public IActionResult Index()
        {
            // Create and populate the dashboard view model with sample data
            var vm = new DashboardViewModel
            {
                // Key performance indicators for the dashboard
                Kpi = new DashboardKpi
                {
                    TotalEquipment = 128,           // Total number of equipment in fleet
                    ActiveRentals = 23,             // Number of currently active rentals
                    PendingMaintenance = 7,         // Equipment pending maintenance
                    FleetAvailable = 84,            // Number of available fleet items
                    FleetAvailablePct = 65,         // Percentage of fleet available
                    AddedThisWeek = 5,              // Equipment added this week
                    ActiveRentalsTodayDelta = +3,   // Change in active rentals today
                    PendingMaintDelta = -2          // Change in pending maintenance
                },
                // List of available equipment by category
                Availability = new List<AvailabilityByCategory>
                {
                    new(){ Category = "PPE",      Available = 56 },
                    new(){ Category = "Vehicles", Available = 12 },
                    new(){ Category = "Drones",   Available = 8  },
                    new(){ Category = "Cameras",  Available = 22 },
                    new(){ Category = "Mics",     Available = 18 },
                    new(){ Category = "Tools",    Available = 14 },
                },
                // Maintenance status donut chart data: OK, Scheduled, Urgent
                MaintDonut = new List<int> { 84, 5, 2 },
                // List of currently active rentals with details
                ActiveRentals = new List<ActiveRentalRow>
                {
                    new(){ RentalId="#R-1029", Client="Starlight Media", Items="FX6 Camera, DJI Mavic 3", OutDate="Oct 12", DueDate="Oct 18", Status="On Rent" },
                    new(){ RentalId="#R-1030", Client="Nova Events", Items="4× Lavalier Mics", OutDate="Oct 13", DueDate="Oct 15", Status="Due Soon" },
                    new(){ RentalId="#R-1031", Client="Ghost Diagnostics", Items="Transit Van, 2× Drones", OutDate="Oct 10", DueDate="Oct 20", Status="On Track" },
                    new(){ RentalId="#R-1032", Client="Filmhouse", Items="RED Komodo", OutDate="Oct 05", DueDate="Oct 16", Status="Overdue" }
                }
            };

            // Pass the populated view model to the dashboard view
            return View(vm);
        }
    }
}