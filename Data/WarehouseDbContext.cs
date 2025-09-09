// Models/WarehouseDbContext.cs
using Microsoft.EntityFrameworkCore;
using WarehouseApp.Models;

namespace WarehouseApp.Data
{
	public class WarehouseDbContext : DbContext
	{
		public WarehouseDbContext(DbContextOptions<WarehouseDbContext> options) : base(options)
		{
		}

		public DbSet<User> Users { get; set; }
		public DbSet<Item> Items { get; set; }
		public DbSet<ToolAttribute> ToolAttributes { get; set; }
		public DbSet<Transaction> Transactions { get; set; }
		public DbSet<Category> Categories { get; set; }

		protected override void OnModelCreating(ModelBuilder modelBuilder)
		{
			// ربط One-to-One بين Item و ToolAttribute
			modelBuilder.Entity<Item>()
				.HasOne(i => i.ToolAttribute)
				.WithOne(t => t.Item)
				.HasForeignKey<ToolAttribute>(t => t.ItemID)
				.OnDelete(DeleteBehavior.Cascade);

			// علاقتين One-to-Many
			modelBuilder.Entity<Transaction>()
				.HasOne(t => t.Item)
				.WithMany()
				.HasForeignKey(t => t.ItemID)
				.OnDelete(DeleteBehavior.Cascade);

			modelBuilder.Entity<Transaction>()
				.HasOne(t => t.User)
				.WithMany()
				.HasForeignKey(t => t.UserID)
				.OnDelete(DeleteBehavior.Restrict);
		}
	}
}
