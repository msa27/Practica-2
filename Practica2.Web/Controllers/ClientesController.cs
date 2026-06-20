using Practica2.Web.EF;
using Practica2.Web.Models;
using Practica2.Web.Servicios;
using System;
using System.Linq;
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
                    // Validar que la cédula no esté en uso
                    var existeCliente = (from C in context.Clientes
                                         where C.Cedula == model.Cedula
                                         select C).FirstOrDefault();

                    if (existeCliente != null)
                    {
                        ViewBag.Mensaje = "La información no se ha podido registrar";
                        return View(model);
                    }

                    context.Clientes.Add(new Clientes
                    {
                        Cedula = model.Cedula,
                        Nombre = model.Nombre,
                        Correo = model.Correo,
                        Estado = true
                    });

                    var response = context.SaveChanges();

                    if (response <= 0)
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
