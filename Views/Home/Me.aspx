<%@ Page Language="C#" MasterPageFile="~/Views/Shared/Site.Master" Inherits="System.Web.Mvc.ViewPage" %>

<asp:Content ID="Content1" ContentPlaceHolderID="TitleContent" runat="server">
    <%: ViewData["Domain"] %>\<%: ViewData["Username"] %>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">
    <h2>Welcome, <%: ViewData["Domain"] %>\<%: ViewData["Username"] %>!</h2>
    <p>
      You're logged in as <b><%: ViewData["Domain"] %>\<%: ViewData["Username"] %></b>, so you can use this page as an OpenID identity page.
    </p>
</asp:Content>
