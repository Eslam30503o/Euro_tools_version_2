using System;
using System.ComponentModel.DataAnnotations;

namespace WarehouseApp.Models
{
    public class User
    {
        public int UserID { get; set; }

        [Required(ErrorMessage = "اسم المستخدم مطلوب")]
        public string Username { get; set; }

        [Required(ErrorMessage = "كلمة السر مطلوبة")]
        [DataType(DataType.Password)]
        public string Password { get; set; }

        [Required(ErrorMessage = "الدور مطلوب")]
        public string Role { get; set; } // Admin, Manager, Supervisor, User

        public DateTime CreatedAt { get; set; } = DateTime.Now;
    }
}
