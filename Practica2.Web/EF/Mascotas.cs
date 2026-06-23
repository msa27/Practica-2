namespace Practica2.Web.EF
{
    public partial class Mascotas
    {
        public long IdMascota { get; set; }
        public string Nombre { get; set; }
        public string Especie { get; set; }
        public string Raza { get; set; }
        public decimal Peso { get; set; }
        public long IdCliente { get; set; }

        public virtual Clientes Clientes { get; set; }
    }
}
