using System.Collections.Generic;
using Fleet_Management_App.Entities;

namespace Fleet_Management_App.Models
{
    /// <summary>
    /// View model for the equipment details page. Wraps a single equipment
    /// record together with all units belonging to the same equipment type.
    /// </summary>
    public class EquipmentDetailsViewModel
    {
        /// <summary>
        /// The primary equipment record for which details are being shown.
        /// </summary>
        public Equipment Equipment { get; set; } = null!;

        /// <summary>
        /// All physical units that share the same category and type as the
        /// primary equipment. Used to display per-unit availability.
        /// </summary>
        public List<Equipment> UnitsOfType { get; set; } = new();
    }
}
