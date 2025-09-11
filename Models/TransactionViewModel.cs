using System.ComponentModel.DataAnnotations;

namespace WarehouseApp.Models
{
    public class TransactionViewModel
    {
        [Required(ErrorMessage = "يجب اختيار المنتج")]
        public int ItemID { get; set; }

        [Required(ErrorMessage = "يجب تحديد الكمية")]
        [Range(1, int.MaxValue, ErrorMessage = "يجب أن تكون الكمية أكبر من صفر")]
        public int Quantity { get; set; }

        [Required(ErrorMessage = "يجب تحديد نوع العملية")]
        public string Action { get; set; } = string.Empty; // مثلا: "سحب" أو "إضافة"

        public string? PerformedBy { get; set; }

        public string? Notes { get; set; }

        public DateTime TransactionDate { get; set; } = DateTime.Now;
    }
}
