<%@ Page Language="C#" Inherits="System.Web.Mvc.ViewPage" ContentType="application/xrds+xml" %>
<?xml version="1.0" encoding="UTF-8"?>
<xrds:XRDS xmlns:xrds="xri://$xrds" xmlns="xri://$xrd*($v*2.0)">
  <XRD>
    <Service priority="10">
      <Type>http://specs.openid.net/auth/2.0/signon</Type>
      <%-- <Type>http://openid.net/extensions/sreg/1.1</Type> --%>
      <URI><%: ViewData["ServerUrl"]%></URI>
    </Service>
    <Service priority="20">
      <Type>http://openid.net/signon/1.0</Type>
      <%-- <Type>http://openid.net/extensions/sreg/1.1</Type> --%>
      <URI><%: ViewData["ServerUrl"] %></URI>
    </Service>
  </XRD>
</xrds:XRDS>