cd ~/ProductAPI

# ── Models ─────────────────────────────────────────────────────────────────
mkdir -p src/ProductAPI/Models
cat > src/ProductAPI/Models/Product.cs << 'CSEOF'
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace ProductAPI.Models;

public class Product
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    public int Id { get; set; }

    [Required]
    [MaxLength(200)]
    public string Name { get; set; } = string.Empty;

    [MaxLength(1000)]
    public string Description { get; set; } = string.Empty;

    [Required]
    [Column(TypeName = "decimal(18,2)")]
    public decimal Price { get; set; }

    [Required]
    public int Quantity { get; set; }

    public bool IsActive { get; set; } = true;

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}
CSEOF

# ── Data / DbContext ───────────────────────────────────────────────────────
mkdir -p src/ProductAPI/Data
cat > src/ProductAPI/Data/AppDbContext.cs << 'CSEOF'
using Microsoft.EntityFrameworkCore;
using ProductAPI.Models;

namespace ProductAPI.Data;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

    public DbSet<Product> Products { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        var seedDate = new DateTime(2024, 1, 1, 0, 0, 0, DateTimeKind.Utc);

        modelBuilder.Entity<Product>().HasData(
            new Product { Id = 1, Name = "Laptop Pro X",
                Description = "High-performance developer laptop, 16GB RAM, 512GB SSD",
                Price = 75000.00m, Quantity = 10, IsActive = true,
                CreatedAt = seedDate, UpdatedAt = seedDate },
            new Product { Id = 2, Name = "Wireless Mouse",
                Description = "Ergonomic wireless mouse with 2.4GHz connectivity",
                Price = 1500.00m, Quantity = 50, IsActive = true,
                CreatedAt = seedDate, UpdatedAt = seedDate },
            new Product { Id = 3, Name = "Mechanical Keyboard",
                Description = "RGB mechanical keyboard with Cherry MX switches",
                Price = 8500.00m, Quantity = 25, IsActive = true,
                CreatedAt = seedDate, UpdatedAt = seedDate }
        );
    }
}
CSEOF

# ── Controller ─────────────────────────────────────────────────────────────
cat > src/ProductAPI/Controllers/ProductsController.cs << 'CSEOF'
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using ProductAPI.Data;
using ProductAPI.Models;

namespace ProductAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
[Produces("application/json")]
public class ProductsController : ControllerBase
{
    private readonly AppDbContext _context;
    private readonly ILogger<ProductsController> _logger;

    public ProductsController(AppDbContext context, ILogger<ProductsController> logger)
    {
        _context = context;
        _logger = logger;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<Product>>> GetProducts(
        [FromQuery] bool? isActive = null,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 10)
    {
        var query = _context.Products.AsQueryable();
        if (isActive.HasValue)
            query = query.Where(p => p.IsActive == isActive.Value);
        var products = await query.OrderBy(p => p.Id)
            .Skip((page - 1) * pageSize).Take(pageSize).ToListAsync();
        return Ok(products);
    }

    [HttpGet("{id:int}")]
    public async Task<ActionResult<Product>> GetProduct(int id)
    {
        var product = await _context.Products.FindAsync(id);
        if (product == null)
            return NotFound(new { message = $"Product with ID {id} not found" });
        return Ok(product);
    }

    [HttpPost]
    public async Task<ActionResult<Product>> CreateProduct([FromBody] Product product)
    {
        if (!ModelState.IsValid) return BadRequest(ModelState);
        product.Id = 0;
        product.CreatedAt = DateTime.UtcNow;
        product.UpdatedAt = DateTime.UtcNow;
        _context.Products.Add(product);
        await _context.SaveChangesAsync();
        return CreatedAtAction(nameof(GetProduct), new { id = product.Id }, product);
    }

    [HttpPut("{id:int}")]
    public async Task<IActionResult> UpdateProduct(int id, [FromBody] Product product)
    {
        if (id != product.Id)
            return BadRequest(new { message = "ID mismatch" });
        var existing = await _context.Products.FindAsync(id);
        if (existing == null)
            return NotFound(new { message = $"Product with ID {id} not found" });
        existing.Name = product.Name;
        existing.Description = product.Description;
        existing.Price = product.Price;
        existing.Quantity = product.Quantity;
        existing.IsActive = product.IsActive;
        existing.UpdatedAt = DateTime.UtcNow;
        await _context.SaveChangesAsync();
        return NoContent();
    }

    [HttpDelete("{id:int}")]
    public async Task<IActionResult> DeleteProduct(int id)
    {
        var product = await _context.Products.FindAsync(id);
        if (product == null)
            return NotFound(new { message = $"Product with ID {id} not found" });
        _context.Products.Remove(product);
        await _context.SaveChangesAsync();
        return NoContent();
    }

    [HttpGet("/health")]
    public IActionResult HealthCheck() =>
        Ok(new { status = "healthy", timestamp = DateTime.UtcNow, version = "1.0.0" });
}
CSEOF

# ── Program.cs ─────────────────────────────────────────────────────────────
cat > src/ProductAPI/Program.cs << 'CSEOF'
using Microsoft.EntityFrameworkCore;
using ProductAPI.Data;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var connectionString = builder.Configuration.GetConnectionString("DefaultConnection")
    ?? throw new InvalidOperationException("Connection string not found.");

builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseMySql(connectionString, ServerVersion.AutoDetect(connectionString),
        o => o.EnableRetryOnFailure(5, TimeSpan.FromSeconds(30), null)));

builder.Services.AddCors(options =>
    options.AddDefaultPolicy(p =>
        p.AllowAnyOrigin().AllowAnyMethod().AllowAnyHeader()));

var app = builder.Build();

using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    db.Database.Migrate();
}

app.UseSwagger();
app.UseSwaggerUI(c => {
    c.SwaggerEndpoint("/swagger/v1/swagger.json", "ProductAPI v1");
    c.RoutePrefix = "swagger";
});

app.UseCors();
app.UseAuthorization();
app.MapControllers();
app.Run();

public partial class Program { }
CSEOF

# ── appsettings.json ───────────────────────────────────────────────────────
cat > src/ProductAPI/appsettings.json << 'CSEOF'
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "*",
  "ConnectionStrings": {
    "DefaultConnection": "Server=localhost;Port=3306;Database=productdb;User=appuser;Password=AppPass@Secure456!;AllowPublicKeyRetrieval=true;SslMode=None;"
  }
}
CSEOF

cat > src/ProductAPI/appsettings.Production.json << 'CSEOF'
{
  "Logging": {
    "LogLevel": {
      "Default": "Warning",
      "Microsoft.AspNetCore": "Error"
    }
  }
}
CSEOF

