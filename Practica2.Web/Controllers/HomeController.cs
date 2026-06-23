using Practica2.Web.Servicios;
using System;
using System.Web.Mvc;

namespace Practica2.Web.Controllers
{
    public class HomeController : Controller
    {
        readonly UtilitarioService utilitario = new UtilitarioService();

        #region Página de inicio

        [HttpGet]
        public ActionResult Index()
        {
            try
            {
                return View();
            }
            catch (Exception ex)
            {
                utilitario.RegistrarErrorBitacora(ex.Message, "Index", 0);
                return View("Error");
            }
        }

        #endregion
    }
}
