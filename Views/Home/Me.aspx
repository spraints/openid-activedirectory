<%@ Page Language="C#" MasterPageFile="~/Views/Shared/Site.Master" Inherits="System.Web.Mvc.ViewPage" %>

<asp:Content ID="Content1" ContentPlaceHolderID="TitleContent" runat="server">
    <%: ViewData["RequestedUser"] %>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">
    <h2>Welcome, <%: ViewData["RequestedUser"] %>!</h2>
    <p>
      You're logged in as <b><%: ViewData["RequestedUser"] %></b>, so you can use this page as an OpenID identity page.
    </p>
</asp:Content>
