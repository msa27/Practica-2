namespace Practica2.Web.EF
{
    using System.Data.Entity;

    public partial class Practica2Entities : DbContext
    {
        public Practica2Entities()
            : base("name=Practica2Entities")
        {
        }

        public virtual DbSet<Clientes> Clientes { get; set; }
        public virtual DbSet<Mascotas> Mascotas { get; set; }

        protected override void OnModelCreating(DbModelBuilder modelBuilder)
        {
            modelBuilder.Entity<Clientes>()
                .ToTable("Clientes")
                .HasKey(c => c.IdCliente);

            modelBuilder.Entity<Clientes>()
                .Property(c => c.IdCliente)
                .HasDatabaseGeneratedOption(System.ComponentModel.DataAnnotations.Schema.DatabaseGeneratedOption.Identity);

            modelBuilder.Entity<Clientes>()
                .Property(c => c.Cedula)
                .IsRequired()
                .HasMaxLength(50);

            modelBuilder.Entity<Clientes>()
                .Property(c => c.Nombre)
                .IsRequired()
                .HasMaxLength(100);

            modelBuilder.Entity<Clientes>()
                .Property(c => c.Correo)
                .IsRequired()
                .HasMaxLength(100);

            modelBuilder.Entity<Mascotas>()
                .ToTable("Mascotas")
                .HasKey(m => m.IdMascota);

            modelBuilder.Entity<Mascotas>()
                .Property(m => m.IdMascota)
                .HasDatabaseGeneratedOption(System.ComponentModel.DataAnnotations.Schema.DatabaseGeneratedOption.Identity);

            modelBuilder.Entity<Mascotas>()
                .Property(m => m.Nombre)
                .IsRequired()
                .HasMaxLength(100);

            modelBuilder.Entity<Mascotas>()
                .Property(m => m.Especie)
                .IsRequired()
                .HasMaxLength(100);

            modelBuilder.Entity<Mascotas>()
                .Property(m => m.Raza)
                .IsRequired()
                .HasMaxLength(100);

            modelBuilder.Entity<Mascotas>()
                .Property(m => m.Peso)
                .HasPrecision(8, 2);

            modelBuilder.Entity<Mascotas>()
                .HasRequired(m => m.Clientes)
                .WithMany(c => c.Mascotas)
                .HasForeignKey(m => m.IdCliente);
        }
    }
}
