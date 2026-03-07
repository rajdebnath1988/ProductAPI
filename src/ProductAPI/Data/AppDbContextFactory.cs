using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;

namespace ProductAPI.Data;

/// <summary>
/// Used ONLY by EF Core CLI tools at design time (migrations).
/// Never used at runtime. Avoids needing a real DB connection to generate migrations.
/// </summary>
public class AppDbContextFactory : IDesignTimeDbContextFactory<AppDbContext>
{
    public AppDbContext CreateDbContext(string[] args)
    {
        var optionsBuilder = new DbContextOptionsBuilder<AppDbContext>();

        // Hardcoded design-time connection string — real DB NOT needed
        // EF just needs to know the provider (MySQL) to generate correct SQL
        optionsBuilder.UseMySql(
            "Server=localhost;Port=3306;Database=productdb;User=root;Password=design_time_only;",
            new MySqlServerVersion(new Version(8, 0, 0))
        );

        return new AppDbContext(optionsBuilder.Options);
    }
}
