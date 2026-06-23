using System;
using System.Diagnostics;

namespace Practica2.Web.Servicios
{
    public class UtilitarioService
    {
        public void RegistrarErrorBitacora(string mensaje, string lugar, int usuario)
        {
            Trace.WriteLine(string.Format(
                "[{0:yyyy-MM-dd HH:mm:ss}] Lugar: {1} | Usuario: {2} | {3}",
                DateTime.Now,
                lugar,
                usuario,
                mensaje));
        }
    }
}
