using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using WarehouseApp.Data;
using Microsoft.EntityFrameworkCore;
using WarehouseApp.Models;
namespace WarehouseApp.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ToolApiController : ControllerBase
    {
        private readonly WarehouseDbContext _context;

        public ToolApiController(WarehouseDbContext context)
        {
            _context = context;
        }

        // GET: api/ToolApi
        [HttpGet]
        public async Task<IActionResult> GetAllTools()
        {
            var tools = await _context.Items
                .Include(i => i.ToolAttribute)
                .Include(i => i.Category)
                .ToListAsync();

            return Ok(tools);
        }

        // GET: api/ToolApi/5
        [HttpGet("{id}")]
        public async Task<IActionResult> GetToolById(int id)
        {
            var tool = await _context.Items
                .Include(i => i.ToolAttribute)
                .FirstOrDefaultAsync(i => i.ItemID == id);

            if (tool == null)
                return NotFound();

            return Ok(tool);
        }

        // POST: api/ToolApi
        [HttpPost]
        public async Task<IActionResult> AddTool([FromBody] Item item)
        {
            _context.Items.Add(item);
            await _context.SaveChangesAsync();
            return Ok(item);
        }
    }
}
