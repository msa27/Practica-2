using Practica2.Web.EF;
using Practica2.Web.Models;
using Practica2.Web.Servicios;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.Mvc;

namespace Practica2.Web.Controllers
{
    public class MascotasController : Controller
    {
        readonly UtilitarioService utilitario = new UtilitarioService();

        #region Registro de mascotas

        [HttpGet]
        public ActionResult Registrar()
        {
            try
            {
                return View(CargarModeloRegistro(0));
            }
            catch (Exception ex)
            {
                utilitario.RegistrarErrorBitacora(ex.Message, "RegistrarMascota", 0);
                return View("Error");
            }
        }

        [HttpPost]
        public ActionResult Registrar(MascotaModel model)
        {
            try
            {
                using (var context = new Practica2Entities())
                {
                    var cliente = (from C in context.Clientes
                                   where C.IdCliente == model.IdCliente && C.Estado == true
                                   select C).FirstOrDefault();

                    if (cliente == null)
                    {
                        ViewBag.Mensaje = "La información no se ha podido registrar";
                        model.Clientes = ObtenerClientesActivos(context, model.IdCliente);
                        return View(model);
                    }

                    var countEspecie = (from M in context.Mascotas
                                        where M.IdCliente == model.IdCliente && M.Especie == model.Especie
                                        select M).Count();

                    if (countEspecie >= 2)
                    {
                        ViewBag.Mensaje = "La información no se ha podido registrar";
                        model.Clientes = ObtenerClientesActivos(context, model.IdCliente);
                        return View(model);
                    }

                    context.Mascotas.Add(new Mascotas
                    {
                        Nombre = model.Nombre,
                        Especie = model.Especie,
                        Raza = model.Raza,
                        Peso = model.Peso,
                        IdCliente = model.IdCliente
                    });

                    context.SaveChanges();
                    return RedirectToAction("Consultar");
                }
            }
            catch (Exception ex)
            {
                utilitario.RegistrarErrorBitacora(ex.Message, "RegistrarMascota", 0);
                return View("Error");
            }
        }

        #endregion

        #region Consulta de mascotas

        [HttpGet]
        public ActionResult Consultar()
        {
            try
            {
                using (var context = new Practica2Entities())
                {
                    var lista = (from M in context.Mascotas
                                 join C in context.Clientes on M.IdCliente equals C.IdCliente
                                 orderby C.Nombre, M.Nombre
                                 select new ConsultaMascotaModel
                                 {
                                     CedulaCliente = C.Cedula,
                                     NombreCliente = C.Nombre,
                                     NombreMascota = M.Nombre,
                                     Especie = M.Especie,
                                     Peso = M.Peso
                                 }).ToList();

                    return View(lista);
                }
            }
            catch (Exception ex)
            {
                utilitario.RegistrarErrorBitacora(ex.Message, "ConsultarMascotas", 0);
                return View("Error");
            }
        }

        #endregion

        #region Métodos auxiliares

        private MascotaModel CargarModeloRegistro(long idClienteSeleccionado)
        {
            using (var context = new Practica2Entities())
            {
                return new MascotaModel
                {
                    IdCliente = idClienteSeleccionado,
                    Clientes = ObtenerClientesActivos(context, idClienteSeleccionado)
                };
            }
        }

        private IEnumerable<SelectListItem> ObtenerClientesActivos(Practica2Entities context, long idClienteSeleccionado)
        {
            var clientes = (from C in context.Clientes
                            where C.Estado == true
                            orderby C.Nombre
                            select new SelectListItem
                            {
                                Value = C.IdCliente.ToString(),
                                Text = C.Cedula + " - " + C.Nombre,
                                Selected = C.IdCliente == idClienteSeleccionado
                            }).ToList();

            clientes.Insert(0, new SelectListItem
            {
                Value = "",
                Text = "Seleccione un cliente",
                Selected = idClienteSeleccionado == 0
            });

            return clientes;
        }

        #endregion
    }
}
