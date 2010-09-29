using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using System.Security.Principal;
using System.Web.Routing;

namespace ad_openid_aspnetmvc.Controllers
{
    [HandleError]
    public class HomeController : Controller
    {
        class AdOpenIdIdentity
        {
            public string Domain { get; set; }
            public string Username { get; set; }

            public string FullName
            {
                get { return Domain + "\\" + Username; }
            }

            public object ToRouteValues()
            {
                return new { domain = Domain, username = Username };
            }

            public override string ToString()
            {
                return FullName;
            }

            public override bool Equals(object obj)
            {
                return Equals(obj as AdOpenIdIdentity);
            }

            public bool Equals(AdOpenIdIdentity other)
            {
                return other != null && other.FullName == FullName;
            }

            public override int GetHashCode()
            {
                return FullName.GetHashCode();
            }

            public static AdOpenIdIdentity From(IPrincipal user)
            {
                if (user == null)
                    return null;
                return From(user.Identity);
            }

            public static AdOpenIdIdentity From(IIdentity iIdentity)
            {
                if (iIdentity == null || !iIdentity.IsAuthenticated)
                    return null;
                return FromFullName(iIdentity.Name);
            }

            public static AdOpenIdIdentity FromFullName(string username)
            {
                var name = username.Split('\\');
                if (name.Length != 2)
                    return null;
                return new AdOpenIdIdentity { Domain = name[0], Username = name[1] };
            }
        }

        private AdOpenIdIdentity CurrentUser
        {
            get { return Session["CurrentUser"] as AdOpenIdIdentity; }
            set { Session["CurrentUser"] = value; }
        }

        private string CurrentUserUrl
        {
            get { return Url.RouteUrl("User", CurrentUser.ToRouteValues()); }
        }

        public ActionResult Login()
        {
            var user = AdOpenIdIdentity.From(User);
            if (user == null)
                throw new Exception("You must be authenticated.");
            CurrentUser = user;
            return Redirect(CurrentUserUrl);
        }

        public ActionResult Index()
        {
            if(CurrentUser != null)
                return Redirect(CurrentUserUrl);
            return Redirect(Url.RouteUrl("Login"));
        }

        public ActionResult Show(string domain, string username)
        {
            ViewData["RequestedUser"] = new AdOpenIdIdentity { Domain = domain, Username = username };
            if (Request.AcceptTypes.Contains(ContentTypes.Xrds))
                return UserXrds();
            if (ViewData["RequestedUser"].Equals(CurrentUser))
                return View("Me");
            return View("NotMe");
        }

        private ActionResult UserXrds()
        {
            return new ContentResult
            {
                ContentType = ContentTypes.Xrds,
                Content = @"<?xml version=""1.0"" encoding=""UTF-8""?>
<xrds:XRDS xmlns:xrds=""xri://$xrds"" xmlns=""xri://$xrd*($v*2.0)"">
  <XRD>
    <Service priority=""0"">
      <!-- Types -->
      <URI>" + Url.RouteUrl("Server", null, Request.Url.Scheme, Request.Url.Host) + @"</URI>
    </Service>
  </XRD>
</xrds:XRDS>"
            };
        }

        class ContentTypes
        {
            public static readonly string Xrds = "application/xrds+xml";
        }
    }
}
