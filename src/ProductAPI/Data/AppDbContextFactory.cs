using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;

namespace ProductAPI.Data;

/// <summary>
/// Design-time factory for EF Core CLI tools (migrations).
/// Not used at runtime. No real DB connection needed.
/// </summary>
public class AppDbContextFactory : IDesignTimeDbContextFactory<AppDbContext>
{
    public AppDbContext CreateDbContext(string[] args)
    {
        var optionsBuilder = new DbContextOptionsBuilder<AppDbContext>();

        // Design-time only — uses hardcoded version, no live DB needed
        // NOSONAR: S2068 - not a real credential, design-time placeholder only
        var designTimeConnection =
            "Server=localhost;Port=3306;Database=productdb;" +
            "User=root;pwd=design_time_placeholder_not_real;";

        optionsBuilder.UseMySql(
            designTimeConnection,
            new MySqlServerVersion(new Version(8, 0, 0))
        );

        return new AppDbContext(optionsBuilder.Options);
    }
}
