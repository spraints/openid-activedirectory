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
            ViewData["Username"] = username;
            if (Request.AcceptTypes.Contains("application/xrds+xml"))
                return UserXrds(domain, username);
            if (User.Identity.Name == ToFullUsername(domain, username))
                return View("Me");
            return View("NotMe");
        }

        private ActionResult UserXrds(string domain, string username)
        {
            throw new NotImplementedException();
        }

        private string ToFullUsername(string domain, string username)
        {
            return String.Join("\\", domain, username);
        }
    }
}
