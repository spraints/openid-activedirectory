<%@ Page Language="C#" MasterPageFile="~/Views/Shared/Site.Master" Inherits="System.Web.Mvc.ViewPage" %>

<asp:Content ID="Content1" ContentPlaceHolderID="TitleContent" runat="server">
    <%: ViewData["Domain"] %>\<%: ViewData["Username"] %>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">
    <h2><%: ViewData["Domain"] %>\<%: ViewData["Username"] %></h2>
    <p>
      Welcome to the OpenID page for <%: ViewData["Domain"] %>\<%: ViewData["Username"] %>. There's not much to do here.
    </p>
</asp:Content>
