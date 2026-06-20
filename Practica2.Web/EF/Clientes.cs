namespace Practica2.Web.EF
{
    using System.Collections.Generic;

    public partial class Clientes
    {
        public Clientes()
        {
            Mascotas = new HashSet<Mascotas>();
        }

        public long IdCliente { get; set; }
        public string Cedula { get; set; }
        public string Nombre { get; set; }
        public string Correo { get; set; }
        public bool Estado { get; set; }

        public virtual ICollection<Mascotas> Mascotas { get; set; }
    }
}
