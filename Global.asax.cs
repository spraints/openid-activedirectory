﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using System.Web.Routing;

namespace ad_openid_aspnetmvc
{
    // Note: For instructions on enabling IIS6 or IIS7 classic mode, 
    // visit http://go.microsoft.com/?LinkId=9394801

    public class MvcApplication : System.Web.HttpApplication
    {
        public static void RegisterRoutes(RouteCollection routes)
        {
            routes.IgnoreRoute("{resource}.axd/{*pathInfo}");

            routes.MapRoute("Home", "", new { controller = "Home", action = "Index" });
            routes.MapRoute("User", "user/{domain}/{username}", new { controller = "Home", action = "Show" });
            routes.MapRoute("Login", "login", new { controller = "Home", action = "Login" });
            routes.MapRoute("Server", "server", new { controller = "Home", action = "Server" });
            routes.MapRoute("Decide", "decide", new { controller = "Home", action = "Decide" });
        }

        protected void Application_Start()
        {
            AreaRegistration.RegisterAllAreas();

            RegisterRoutes(RouteTable.Routes);
        }
    }
}