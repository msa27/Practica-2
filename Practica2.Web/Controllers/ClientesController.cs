using Practica2.Web.EF;
using Practica2.Web.Models;
using Practica2.Web.Servicios;
using System;
using System.Data.Entity.Core.Objects;
using System.Web.Mvc;

namespace Practica2.Web.Controllers
{
    public class ClientesController : Controller
    {
        readonly UtilitarioService utilitario = new UtilitarioService();

        #region Registro de clientes

        [HttpGet]
        public ActionResult Registrar()
        {
            try
            {
                return View(new ClienteModel());
            }
            catch (Exception ex)
            {
                utilitario.RegistrarErrorBitacora(ex.Message, "RegistrarCliente", 0);
                return View("Error");
            }
        }

        [HttpPost]
        public ActionResult Registrar(ClienteModel model)
        {
            try
            {
                using (var context = new Practica2Entities())
                {
                    var resultadoParam = new ObjectParameter("Resultado", typeof(int));
                    context.spRegistrarCliente(model.Cedula, model.Nombre, model.Correo, resultadoParam);

                    var resultado = Convert.ToInt32(resultadoParam.Value);

                    if (resultado != 1)
                    {
                        ViewBag.Mensaje = "La información no se ha podido registrar";
                        return View(model);
                    }

                    return RedirectToAction("Index", "Home");
                }
            }
            catch (Exception ex)
            {
                utilitario.RegistrarErrorBitacora(ex.Message, "RegistrarCliente", 0);
                return View("Error");
            }
        }

        #endregion
    }
}
