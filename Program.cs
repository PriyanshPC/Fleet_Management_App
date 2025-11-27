using Fleet_Management_App.Entities;
using Microsoft.AspNetCore.Authentication.Cookies;

var builder = WebApplication.CreateBuilder(args);

// MVC
builder.Services.AddControllersWithViews();

//Register EF Core DbContext (connection is configured in OnConfiguring)
builder.Services.AddDbContext<GhostbustersFleetContext>();

// Cookie-based authentication
builder.Services.AddAuthentication(CookieAuthenticationDefaults.AuthenticationScheme)
    .AddCookie(options =>
    {
        options.LoginPath = "/Auth/Login";        // where to send unauthenticated users
        options.AccessDeniedPath = "/Auth/Login"; // simple for now
        options.SlidingExpiration = false;
    });

builder.Services.AddAuthorization();

var app = builder.Build();

// Standard middleware
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Home/Error");
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseStaticFiles();

app.UseRouting();

// **Order matters**: auth before endpoints
app.UseAuthentication();
app.UseAuthorization();

// Default route
app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Auth}/{action=Login}/{id?}");

app.Run();
