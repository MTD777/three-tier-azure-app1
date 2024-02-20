using _3tier_webapp.Data;
using Microsoft.EntityFrameworkCore;
var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddRazorPages();

//SQL DB Config

// Add services to the container.
builder.Services.AddDbContext<VotingContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("VotingContext")));

var app = builder.Build();


// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error");
    // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
    app.UseHsts();
}


app.UseHttpsRedirection();
app.UseStaticFiles();

app.UseRouting();

app.UseAuthorization();

app.MapRazorPages();

app.Run();

// This is for adding Azure SQL Database

// public void ConfigureServices(IServiceCollection services)
// {
//     services.AddDbContext<VotingContext>(options =>
//         options.UseSqlServer(Configuration.GetConnectionString("VotingContext")));
// }
