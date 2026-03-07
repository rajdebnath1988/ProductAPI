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
