using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace Fleet_Management_App.Controllers
{
    // Controller responsible for user authentication (login/logout)
    public class AuthController : Controller
    {
        // Hardcoded credentials for demonstration purposes
        private const string USERNAME = "admin";
        private const string PASSWORD = "admin";
        // Session key for tracking failed login attempts
        private const string FAIL_KEY = "login_fail_count";

        [HttpGet]
        [AllowAnonymous]
        // Displays the login page. Redirects authenticated users to the dashboard.
        public IActionResult Login(string? returnUrl = null)
        {
            if (User?.Identity?.IsAuthenticated == true)
                return RedirectToAction("Index", "Dashboard");

            ViewData["ReturnUrl"] = returnUrl;
            return View();
        }

        [HttpPost]
        [AllowAnonymous]
        [ValidateAntiForgeryToken]
        // Handles login form submission, validates credentials, manages failed attempts, and signs in the user.
        public async Task<IActionResult> Login(string username, string password, bool remember)
        {
            const int MAX_FAILS = 3;
            // Retrieve the current number of failed login attempts from session
            int fails = HttpContext.Session.GetInt32(FAIL_KEY) ?? 0;

            // Lock account after maximum failed attempts
            if (fails >= MAX_FAILS)
            {
                TempData["LoginError"] = "Your account is locked after 3 failed attempts. Please contact IT.";
                return View();
            }

            // Validate credentials
            if (string.Equals(username, USERNAME, StringComparison.OrdinalIgnoreCase) && password == PASSWORD)
            {
                // Reset failed attempts on successful login
                HttpContext.Session.Remove(FAIL_KEY);

                // Create user claims for authentication
                var claims = new List<Claim>
                {
                    new Claim(ClaimTypes.Name, "Administrator"),
                    new Claim("username", USERNAME)
                };
                var identity = new ClaimsIdentity(claims, "FleetCookie");
                var principal = new ClaimsPrincipal(identity);

                // Set authentication properties (persistent cookie, expiration, refresh allowed)
                var props = new AuthenticationProperties
                {
                    IsPersistent = remember,
                    ExpiresUtc = DateTimeOffset.UtcNow.AddHours(8),
                    AllowRefresh = true
                };

                // Sign in the user with the specified authentication scheme
                await HttpContext.SignInAsync("FleetCookie", principal, props);
                return RedirectToAction("Index", "Dashboard");
            }

            // Increment failed login attempts and update session
            fails++;
            HttpContext.Session.SetInt32(FAIL_KEY, fails);

            // Display appropriate error message based on remaining attempts
            if (fails >= MAX_FAILS)
            {
                TempData["LoginError"] = "Your account is locked after 3 failed attempts. Please contact IT.";
            }
            else
            {
                int remaining = MAX_FAILS - fails;
                TempData["LoginError"] = $"Incorrect username or password. ({remaining} attempt{(remaining == 1 ? "" : "s")} left)";
            }

            return View();
        }

        [Authorize]
        // Logs out the authenticated user, clears session, and redirects to login page.
        public async Task<IActionResult> Logout()
        {
            await HttpContext.SignOutAsync("FleetCookie");
            HttpContext.Session.Clear();
            return RedirectToAction("Login");
        }
    }
}