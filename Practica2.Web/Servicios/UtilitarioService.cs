using Practica2.Web.EF;
using System;

namespace Practica2.Web.Servicios
{
    public class UtilitarioService
    {
        public void RegistrarErrorBitacora(string mensaje, string lugar, int usuario)
        {
            try
            {
                using (var context = new Practica2Entities())
                {
                    context.spRegistrarError(mensaje, lugar, usuario);
                }
            }
            catch
            {
                // Si falla la bitácora en BD, no propagar la excepción original
            }
        }
    }
}
