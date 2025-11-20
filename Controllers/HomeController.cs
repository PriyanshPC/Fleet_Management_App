using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Mvc;

namespace Fleet_Management_App.Controllers
{
    public class HomeController : Controller
    {
        // Optional: if someone hits "/", decide where to send them.
        public IActionResult Index()
        {
            if (User?.Identity?.IsAuthenticated == true)
            {
                // Already logged in → go to dashboard
                return RedirectToAction("Index", "Dashboard");
            }

            // Not logged in → go to login page
            return RedirectToAction("Login", "Auth");
        }

        // Handles logout and sends user to Auth/Login
        [HttpGet]
        public async Task<IActionResult> Logout()
        {
            // Sign out of the cookie auth scheme
            await HttpContext.SignOutAsync(CookieAuthenticationDefaults.AuthenticationScheme);

            // Redirect to the login page
            return RedirectToAction("Login", "Auth");
        }
    }
}
