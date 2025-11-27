using System.Linq;
using System.Threading.Tasks;
using Fleet_Management_App.Entities;
using Fleet_Management_App.Models;   // ⬅️ add this
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
                .ThenBy(e => e.EquipmentType)
                .ToListAsync();

            return View(equipment);
        }

        /// <param name="id">EquipmentCode (e.g., "EQ-PUP-001").</param>
        /// <returns>Details view or 404 if not found.</returns>
        public async Task<IActionResult> Details(string id)
        {
            if (string.IsNullOrWhiteSpace(id))
            {
                return NotFound();
            }

            // Load the primary equipment record by its unique code
            var equipment = await _context.Equipment
                .AsNoTracking()
                .FirstOrDefaultAsync(e => e.EquipmentCode == id);

            if (equipment == null)
            {
                return NotFound();
            }

            // Load all units that share the same category and type so that the
            // details page can show per-unit availability for this equipment family.
            var unitsOfType = await _context.Equipment
                .AsNoTracking()
                .Where(e =>
                    e.EquipmentCategory == equipment.EquipmentCategory &&
                    e.EquipmentType == equipment.EquipmentType)
                .OrderBy(e => e.EquipmentCode)
                .ToListAsync();

            var viewModel = new EquipmentDetailsViewModel
            {
                Equipment = equipment,
                UnitsOfType = unitsOfType
            };

            return View(viewModel);
        }
    }
}
