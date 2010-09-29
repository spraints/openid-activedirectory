<%@ Page Language="C#" MasterPageFile="~/Views/Shared/Site.Master" Inherits="System.Web.Mvc.ViewPage" %>

<asp:Content ID="Content1" ContentPlaceHolderID="TitleContent" runat="server">
    Home Page
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">
    <dl>
    <dt>Domain:</dt><dd><%: ViewData["Domain"] %></dd>
    <dt>User:</dt><dd><%: ViewData["User"] %></dd>
    </dl>
</asp:Content>
