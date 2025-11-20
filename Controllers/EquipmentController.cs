using System.Linq;
using System.Threading.Tasks;
using Fleet_Management_App.Data.Entities;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Fleet_Management_App.Controllers
{
    // Controller for managing equipment-related views and actions
    [Authorize] // Restricts access to authenticated users
    public class EquipmentController : Controller
    {
        private readonly GhostbustersFleetContext _context;

        public EquipmentController(GhostbustersFleetContext context)
        {
            _context = context;
        }

        /// <summary>
        /// Displays the equipment list page, populated from the database.
        /// </summary>
        /// <returns>View with all equipment.</returns>
        public async Task<IActionResult> List()
        {
            var equipment = await _context.Equipment
                .OrderBy(e => e.EquipmentCategory)
                .ThenBy(e => e.EquipmentName)
                .ToListAsync();

            return View(equipment);
        }

        /// <summary>
        /// Displays details for a specific equipment asset, including related
        /// vehicle, rental history, and maintenance events.
        /// Uses EquipmentCode as the user-facing ID in the URL.
        /// </summary>
        /// <param //name="id">EquipmentCode (e.g., "VEH-001").</param>
        /// <returns>Details view or 404 if not found.</returns>
        public async Task<IActionResult> Details(string id)
        {
            if (string.IsNullOrWhiteSpace(id))
            {
                return NotFound();
            }

            var equipment = await _context.Equipment
                .Include(e => e.Vehicle)
                .Include(e => e.RentedEquipments)
                    .ThenInclude(re => re.Rental)
                        .ThenInclude(r => r.Customer)
                .Include(e => e.MaintenanceEvents)
                .FirstOrDefaultAsync(e => e.EquipmentCode == id);

            if (equipment == null)
            {
                return NotFound();
            }

            return View(equipment);
        }
    }
}
