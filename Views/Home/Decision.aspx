<%@ Page Title="" Language="C#" MasterPageFile="~/Views/Shared/Site.Master" Inherits="System.Web.Mvc.ViewPage<ad_openid_aspnetmvc.Controllers.DecisionViewModel>" %>
<%@ Import Namespace="ad_openid_aspnetmvc.Helpers" %>

<asp:Content ID="Content1" ContentPlaceHolderID="TitleContent" runat="server">
  Decision
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">

  <form action="<%: Url.Action("Decide") %>" method="post">
    <p>
      Do you want to sign into
      <b><%: ViewData.Model.OpenIdRequest.Realm %></b>
      with your Active Directory account
      <b><%: ViewData.Model.OpenIdRequest.LocalIdentifier %></b>
      ?
    </p>
    <% if(ViewData.Model.SregRequest != null) { %>
      <%: Html.OpenIdSregField(ViewData.Model.SregRequest, "Nickname") %>
      <%: Html.OpenIdSregField(ViewData.Model.SregRequest, "Email") %>
      <%: Html.OpenIdSregField(ViewData.Model.SregRequest, "BirthDate") %>
      <%: Html.OpenIdSregField(ViewData.Model.SregRequest, "Gender") %>
      <%: Html.OpenIdSregField(ViewData.Model.SregRequest, "PostalCode") %>
      <%: Html.OpenIdSregField(ViewData.Model.SregRequest, "Country") %>
      <%: Html.OpenIdSregField(ViewData.Model.SregRequest, "Language") %>
      <%: Html.OpenIdSregField(ViewData.Model.SregRequest, "TimeZone") %>
    <% } %>
    <input type="submit" name="trust" value="Sign in" />
    <input type="submit" name="no_trust" value="Cancel" />
  </form>

</asp:Content>
