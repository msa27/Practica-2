using System.Collections.Generic;
using System.Web.Mvc;

namespace Practica2.Web.Models
{
    public class MascotaModel
    {
        public string Nombre { get; set; }
        public string Especie { get; set; }
        public string Raza { get; set; }
        public decimal Peso { get; set; }
        public long IdCliente { get; set; }
        public IEnumerable<SelectListItem> Clientes { get; set; }
    }
}
