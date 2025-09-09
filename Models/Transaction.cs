// Models/Transaction.cs
using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace WarehouseApp.Models
{
    public class Transaction
    {
        [Key]
        public int TransactionID { get; set; }

        [Required]
        public int ItemID { get; set; }

        [Required]
        public int UserID { get; set; }

        [Required]
        public string Action { get; set; } // مثلاً: "Add", "Remove"

        public int QuantityChange { get; set; }

        public DateTime Timestamp { get; set; } = DateTime.Now;

        // Navigation properties
        public Item Item { get; set; }
        public User User { get; set; }
    }
}
