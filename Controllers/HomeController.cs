using System;
using System.Linq;
using System.Security.Principal;
using System.Web.Mvc;
using DotNetOpenAuth.Messaging;
using DotNetOpenAuth.OpenId.Extensions.SimpleRegistration;
using DotNetOpenAuth.OpenId.Provider;

namespace ad_openid_aspnetmvc.Helpers
{
    public static partial class Ext
    {
        public static MvcHtmlString OpenIdSregField<T>(this HtmlHelper<T> html, ClaimsRequest request, string field)
        {
            if (request == null)
                throw new ArgumentNullException("request");
            var t = typeof(ClaimsRequest);
            var p = t.GetProperty(field);
            if (p == null)
                throw new ArgumentOutOfRangeException("field", field, "Not a property on ClaimsRequest");
            var demandLevel = (DemandLevel) p.GetValue(request, null);
            if(demandLevel == DemandLevel.NoRequest)
                return MvcHtmlString.Empty;
            var id = "sreg." + field;
            return MvcHtmlString.Create("<div>" +
                "<label for=\"" + id + "\">" + field + (demandLevel == DemandLevel.Require ? " (required)" : "") + "</label>" +
                "<input type=\"text\" id=\"" + id + "\" name=\"" + id + "\" />" +
                "</div>");
        }
    }
}

namespace ad_openid_aspnetmvc.Controllers
{
    public class DecisionViewModel
    {
        public IAuthenticationRequest OpenIdRequest { get; set; }
        public ClaimsRequest SregRequest { get; set; }
    }

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
            get { return Url.RouteUrl("User", CurrentUser.ToRouteValues(), Request.Url.Scheme); }
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
            ViewData["ServerUrl"] = Url.RouteUrl("Server", null, Request.Url.Scheme, Request.Url.Host);
            if (Request.AcceptTypes.Contains(ContentTypes.Xrds))
                return View("Xrds");
            if (ViewData["RequestedUser"].Equals(CurrentUser))
                return View("Me");
            return View("NotMe");
        }

        internal static OpenIdProvider OpenIdProvider = new OpenIdProvider();

        internal static IAuthenticationRequest PendingRequest
        {
            get { return ProviderEndpoint.PendingAuthenticationRequest; }
            set { ProviderEndpoint.PendingAuthenticationRequest = value; }
        }

        public ActionResult Decide()
        {
            if (PendingRequest != null)
            {
                PendingRequest.IsAuthenticated = !String.IsNullOrEmpty(Request.Params["trust"]);
                var sreg = PendingRequest.GetExtension(typeof(ClaimsRequest)) as ClaimsRequest;
                if (sreg != null)
                {
                    var response = sreg.CreateResponse();
                    Set("sreg.BirthDate", x => response.BirthDateRaw = x);
                    Set("sreg.Country", x => response.Country = x);
                    Set("sreg.Email", x => response.Email = x);
                    Set("sreg.FullName", x => response.FullName = x);
                    Set("sreg.Gender", x => response.Gender = (x.ToLowerInvariant().StartsWith("m") ? Gender.Male : Gender.Female));
                    Set("sreg.Language", x => response.Language = x);
                    Set("sreg.Nickname", x => response.Nickname = x);
                    Set("sreg.PostalCode", x => response.PostalCode = x);
                    Set("sreg.TimeZone", x => response.TimeZone = x);
                    PendingRequest.AddResponseExtension(response);

                }
                return OpenIdProvider.PrepareResponse(PendingRequest).AsActionResult();
            }
            return Redirect(Url.RouteUrl("Home"));
        }

        private void Set(string paramName, Action<string> action)
        {
            foreach (var value in Request.Params.GetValues(paramName) ?? new string[0])
                if(!String.IsNullOrEmpty(value))
                    action(value);
        }

        [ValidateInput(false)]
        public ActionResult Server()
        {
            var request = OpenIdProvider.GetRequest();
            if (request != null)
            {
                var authRequest = request as IAuthenticationRequest;
                if (authRequest != null)
                {
                    // Not sure how useful this is, until I start doing sreg. Even then, it'd be nice to keep it out of the session.
                    PendingRequest = authRequest;

                    // Make sure the user is logged in
                    if (CurrentUser == null)
                        return View("LoginRequired");

                    // Make sure the user is the right user.
                    if (authRequest.IsDirectedIdentity)
                        authRequest.LocalIdentifier = CurrentUserUrl;
                    else if (CurrentUserUrl != authRequest.LocalIdentifier)
                        return View("LoginRequired");

                    // Not sure what this does, but the sample does it so It Must Be Important (tm)
                    if (!authRequest.IsDelegatedIdentifier)
                        authRequest.ClaimedIdentifier = authRequest.LocalIdentifier;

                    // My ruby version did this instead:
                    return View("Decision", new DecisionViewModel { OpenIdRequest = authRequest, SregRequest = authRequest.GetExtension(typeof(ClaimsRequest)) as ClaimsRequest });
                }
                if (request.IsResponseReady)
                {
                    return OpenIdProvider.PrepareResponse(request).AsActionResult();
                }
                else
                {
                    return View("LoginRequired");
                }
            }
            else
            {
                return View();
            }
        }

        class ContentTypes
        {
            public static readonly string Xrds = "application/xrds+xml";
        }
    }
}
