using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace Fleet_Management_App.Controllers
{
    public class AuthController : Controller
    {
        private const string USERNAME = "admin";
        private const string PASSWORD = "admin";
        private const string FAIL_KEY = "login_fail_count";

        [HttpGet]
        [AllowAnonymous]
        public IActionResult Login(string? returnUrl = null)
        {
            // If already signed in, go home
            if (User?.Identity?.IsAuthenticated == true) return RedirectToAction("Index", "Dashboard");
            ViewData["ReturnUrl"] = returnUrl;
            return View();
        }

        [HttpPost]
        [AllowAnonymous]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Login(string username, string password, bool remember)
        {
            const int MAX_FAILS = 3;
            int fails = HttpContext.Session.GetInt32(FAIL_KEY) ?? 0;

            if (fails >= MAX_FAILS)
            {
                TempData["LoginError"] = "Your account is locked after 3 failed attempts. Please contact IT.";
                return View();
            }

            if (string.Equals(username, USERNAME, StringComparison.OrdinalIgnoreCase) && password == PASSWORD)
            {
                HttpContext.Session.Remove(FAIL_KEY);

                var claims = new List<Claim>{
            new Claim(ClaimTypes.Name, "Administrator"),
            new Claim("username", USERNAME)
        };
                var identity = new ClaimsIdentity(claims, "FleetCookie");
                var principal = new ClaimsPrincipal(identity);

                var props = new AuthenticationProperties
                {
                    IsPersistent = remember,
                    ExpiresUtc = DateTimeOffset.UtcNow.AddHours(8),
                    AllowRefresh = true
                };

                await HttpContext.SignInAsync("FleetCookie", principal, props);
                return RedirectToAction("Index", "Dashboard");
            }

            // failure path
            fails++;
            HttpContext.Session.SetInt32(FAIL_KEY, fails);

            if (fails >= MAX_FAILS)
            {
                TempData["LoginError"] = "Your account is locked after 3 failed attempts. Please contact IT.";
            }
            else
            {
                int remaining = MAX_FAILS - fails; // 2 → 1 → 0
                TempData["LoginError"] = $"Incorrect username or password. ({remaining} attempt{(remaining == 1 ? "" : "s")} left)";
            }

            return View();
        }


        [Authorize]
        public async Task<IActionResult> Logout()
        {
            await HttpContext.SignOutAsync("FleetCookie");
            HttpContext.Session.Clear();
            return RedirectToAction("Login");
        }
    }
}
