using Fleet_Management_App.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Fleet_Management_App.Controllers
{
    [Authorize]
    public class DashboardController : Controller
    {
        public IActionResult Index()
        {
            var vm = new DashboardViewModel
            {
                Kpi = new DashboardKpi
                {
                    TotalEquipment = 128,
                    ActiveRentals = 23,
                    PendingMaintenance = 7,
                    FleetAvailable = 84,
                    FleetAvailablePct = 65,
                    AddedThisWeek = 5,
                    ActiveRentalsTodayDelta = +3,
                    PendingMaintDelta = -2
                },
                Availability = new List<AvailabilityByCategory>
                {
                    new(){ Category = "PPE",      Available = 56 },
                    new(){ Category = "Vehicles", Available = 12 },
                    new(){ Category = "Drones",   Available = 8  },
                    new(){ Category = "Cameras",  Available = 22 },
                    new(){ Category = "Mics",     Available = 18 },
                    new(){ Category = "Tools",    Available = 14 },
                },
                MaintDonut = new List<int> { 84, 5, 2 }, // OK, Scheduled, Urgent
                ActiveRentals = new List<ActiveRentalRow>
                {
                    new(){ RentalId="#R-1029", Client="Starlight Media", Items="FX6 Camera, DJI Mavic 3", OutDate="Oct 12", DueDate="Oct 18", Status="On Rent" },
                    new(){ RentalId="#R-1030", Client="Nova Events", Items="4× Lavalier Mics", OutDate="Oct 13", DueDate="Oct 15", Status="Due Soon" },
                    new(){ RentalId="#R-1031", Client="Ghost Diagnostics", Items="Transit Van, 2× Drones", OutDate="Oct 10", DueDate="Oct 20", Status="On Track" },
                    new(){ RentalId="#R-1032", Client="Filmhouse", Items="RED Komodo", OutDate="Oct 05", DueDate="Oct 16", Status="Overdue" }
                }
            };

            return View(vm);
        }
    }
}
