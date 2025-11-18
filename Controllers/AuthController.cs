using System.Collections.Generic;
using System.Security.Claims;
using System.Threading.Tasks;
using Fleet_Management_App.Data.Entities;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Fleet_Management_App.Controllers.Api
{
    [ApiController]
    [Route("api/[controller]")]
    public class AuthController : ControllerBase
    {
        private readonly GhostbustersFleetContext _context;

        public AuthController(GhostbustersFleetContext context)
        {
            _context = context;
        }

        public class LoginRequest
        {
            public string Username { get; set; } = string.Empty;
            public string Password { get; set; } = string.Empty;
        }

        public class LoginResponse
        {
            public bool Success { get; set; }
            public string? Message { get; set; }
            public string? EmployeeName { get; set; }
        }

        // POST: /api/auth/login
        [HttpPost("login")]
        public async Task<ActionResult<LoginResponse>> Login([FromBody] LoginRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.Username) ||
                string.IsNullOrWhiteSpace(request.Password))
            {
                return BadRequest(new LoginResponse
                {
                    Success = false,
                    Message = "Username and password are required."
                });
            }

            // Check Employee table
            var user = await _context.Employees
                .FirstOrDefaultAsync(e =>
                    e.Username == request.Username &&
                    e.Password == request.Password); // TODO: hash in real app

            if (user == null)
            {
                return Unauthorized(new LoginResponse
                {
                    Success = false,
                    Message = "Invalid username or password."
                });
            }

            // Build identity + claims for cookie
            var claims = new List<Claim>
            {
                new Claim(ClaimTypes.NameIdentifier, user.EmployeeId.ToString()),
                new Claim(ClaimTypes.Name, user.Name),
                new Claim("username", user.Username)
            };

            var identity = new ClaimsIdentity(
                claims,
                CookieAuthenticationDefaults.AuthenticationScheme);

            var principal = new ClaimsPrincipal(identity);

            await HttpContext.SignInAsync(
            CookieAuthenticationDefaults.AuthenticationScheme,
            principal);

            return Ok(new LoginResponse
            {
                Success = true,
                EmployeeName = user.Name,
                Message = "Login successful."
            });
        }
    }
}
