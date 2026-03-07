using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging.Abstractions;
using Microsoft.AspNetCore.Mvc;
using ProductAPI.Controllers;
using ProductAPI.Data;
using ProductAPI.Models;
using Xunit;

namespace ProductAPI.Tests;

public class ProductsControllerTests
{
    private static AppDbContext GetInMemoryContext(string dbName)
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(databaseName: dbName).Options;
        return new AppDbContext(options);
    }

    [Fact]
    public async Task GetProducts_ReturnsOk_WithAllProducts()
    {
        using var context = GetInMemoryContext(nameof(GetProducts_ReturnsOk_WithAllProducts));
        context.Products.AddRange(
            new Product { Name = "Item1", Price = 100, Quantity = 5 },
            new Product { Name = "Item2", Price = 200, Quantity = 10 });
        await context.SaveChangesAsync();
        var controller = new ProductsController(context, NullLogger<ProductsController>.Instance);
        var result = await controller.GetProducts();
        var ok = Assert.IsType<OkObjectResult>(result.Result);
        var products = Assert.IsAssignableFrom<IEnumerable<Product>>(ok.Value);
        Assert.Equal(2, products.Count());
    }

    [Fact]
    public async Task GetProduct_ReturnsNotFound_WhenMissing()
    {
        using var context = GetInMemoryContext(nameof(GetProduct_ReturnsNotFound_WhenMissing));
        var controller = new ProductsController(context, NullLogger<ProductsController>.Instance);
        var result = await controller.GetProduct(999);
        Assert.IsType<NotFoundObjectResult>(result.Result);
    }

    [Fact]
    public async Task CreateProduct_ReturnsCreated()
    {
        using var context = GetInMemoryContext(nameof(CreateProduct_ReturnsCreated));
        var controller = new ProductsController(context, NullLogger<ProductsController>.Instance);
        var result = await controller.CreateProduct(
            new Product { Name = "New", Price = 100, Quantity = 5 });
        var created = Assert.IsType<CreatedAtActionResult>(result.Result);
        var product = Assert.IsType<Product>(created.Value);
        Assert.Equal("New", product.Name);
    }

    [Fact]
    public async Task DeleteProduct_ReturnsNoContent()
    {
        using var context = GetInMemoryContext(nameof(DeleteProduct_ReturnsNoContent));
        var p = new Product { Name = "ToDelete", Price = 100, Quantity = 1 };
        context.Products.Add(p);
        await context.SaveChangesAsync();
        var controller = new ProductsController(context, NullLogger<ProductsController>.Instance);
        var result = await controller.DeleteProduct(p.Id);
        Assert.IsType<NoContentResult>(result);
    }
}
