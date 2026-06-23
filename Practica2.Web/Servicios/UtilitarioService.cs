using System.Diagnostics;

namespace Practica2.Web.Servicios
{
    public class UtilitarioService
    {
        public void RegistrarErrorBitacora(string mensaje, string lugar, int usuario)
        {
            Trace.TraceError("[{0}] Usuario={1}: {2}", lugar, usuario, mensaje);
        }
    }
}
