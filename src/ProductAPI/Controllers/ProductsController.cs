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
        _logger.LogInformation("Fetching products page={Page} size={Size}", page, pageSize);
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
        {
            _logger.LogWarning("Product {Id} not found", id);
            return NotFound(new { message = $"Product with ID {id} not found" });
        }
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
        _logger.LogInformation("Created product {Id}: {Name}", product.Id, product.Name);
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
        _logger.LogInformation("Updated product {Id}", id);
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
        _logger.LogInformation("Deleted product {Id}", id);
        return NoContent();
    }

    [HttpGet("/health")]
    public IActionResult HealthCheck() =>
        Ok(new { status = "healthy", timestamp = DateTime.UtcNow, version = "1.0.0" });
}
