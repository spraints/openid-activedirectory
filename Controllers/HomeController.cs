using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;

namespace ad_openid_aspnetmvc.Controllers
{
    [HandleError]
    public class HomeController : Controller
    {
        public ActionResult Index()
        {
            var name = User.Identity.Name.Split('\\');
            return Redirect(Url.RouteUrl("User", new { domain = name[0], username = name[1]}));
        }

        public ActionResult Show(string domain, string username)
        {
            ViewData["Domain"] = domain;
            ViewData["User"] = username;
            return View("Index");
        }

        public ActionResult About()
        {
            return View();
        }
    }
}
