using Microsoft.EntityFrameworkCore;
using WarehouseApp.Data;
using WarehouseApp.Models; // لو DbContext موجود في Models
var builder = WebApplication.CreateBuilder(args);

// ✅ ربط DbContext بقاعدة البيانات
builder.Services.AddDbContext<WarehouseDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
// Add services to the container.
builder.Services.AddControllersWithViews();
builder.Services.AddAuthentication("WarehouseAuth")
    .AddCookie("WarehouseAuth", options =>
    {
        options.LoginPath = "/Login"; // لو المستخدم مش مسجل دخول يروح على دي
        options.AccessDeniedPath = "/Login/AccessDenied"; // هذا مهم

    });

builder.Services.AddAuthorization(); // لو هتستخدم [Authorize]

var app = builder.Build();

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Home/Error");
    // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
    app.UseHsts();
}

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}


app.UseHttpsRedirection();
app.UseStaticFiles();

app.UseRouting();
app.UseAuthentication();
app.UseAuthorization();

app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Login}/{action=Index}/{id?}");

app.Run();