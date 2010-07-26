require 'rubygems'
require 'bundler'
Bundler.setup

task :default => :aspnet

desc 'Get the app ready to run under cover of ASP.NET'
task :aspnet => %W(aspnet:copybin logdir aspnet:webconfig)

namespace :aspnet do
  desc "Copies required binaries from IronRuby to public/bin."
  task :copybin do
    defined?(RUBY_ENGINE) && (RUBY_ENGINE == 'ironruby') or fail "You must run this task with IronRuby."
    actual_dotnet   = System::Runtime::InteropServices::RuntimeEnvironment.get_system_version
    expected_dotnet = 'v4.0.30319'
    actual_dotnet == expected_dotnet or fail "You must be using .NET #{expected_dotnet}, but you're using .NET #{actual_dotnet}."
    require 'rbconfig'
    %W(
      IronRuby.dll
      IronRuby.Libraries.dll
      IronRuby.Libraries.YAML.dll
      Microsoft.Dynamic.dll
      Microsoft.Scripting.dll
      Microsoft.Scripting.Metadata.dll
      ir.exe
    ).each do |dll|
      cp "#{RbConfig::TOPDIR}/bin/#{dll}", "public/bin/#{dll}"
    end
  end

  def type_details(t)
    case t
    when String
      type_details(System::Type.get_type(t))
    else
      "#{t.full_name}, #{t.assembly.full_name}"
    end
  end

  def asm_redirect name, old_version
    assembly = System::AppDomain.current_domain.get_assemblies.select { |a| a.get_name.name == name }.first
    assembly or fail "Assembly #{name} is not currently loaded."
    assembly_name = assembly.get_name
    <<END_REDIRECT
      <dependentAssembly>
        <assemblyIdentity name="#{name}" publicKeyToken="#{System::BitConverter.to_string(assembly_name.get_public_key_token).gsub('-','')}" />
        <bindingRedirect oldVersion="#{old_version}" newVersion="#{assembly_name.version}" />
      </dependentAssembly>
END_REDIRECT
  end

  desc 'Create a log directory for IronRuby::Rack'
  directory 'logdir'

  desc 'Generate web.config'
  task :webconfig do
    defined? IRONRUBY_VERSION or fail "You must be using IronRuby to do this."
    output_file = 'public/web.config'
    rake_output_message "Create #{output_file}"
    open output_file, 'w' do |f|
      f.puts <<END_CONFIG
<?xml version="1.0"?>
<configuration>
  <configSections>
    <section name="microsoft.scripting" requirePermission="false" type="#{type_details 'Microsoft.Scripting.Hosting.Configuration.Section, Microsoft.Scripting'}"/>
  </configSections>

  <microsoft.scripting debugMode="false">
    <languages>
      <language extensions=".rb" displayName="IronRuby" type="#{type_details 'IronRuby.Runtime.RubyContext, IronRuby'}" names="IronRuby;Ruby;rb"/>
    </languages>
    <options>
      <set language="Ruby" option="LibraryPaths" value="#{RbConfig::CONFIG['topdir']};#{RbConfig::CONFIG['rubylibdir']};#{RbConfig::CONFIG['sitelibdir']}"/>
    </options>
  </microsoft.scripting>

  <system.web>
    <compilation debug="false" />
  </system.web>

  <system.webServer>
    <handlers>
      <add name="IronRuby-Rack" path="*" verb="*" type="IronRubyRack.AspNetHandlerFactory, IronRuby.Rack" preCondition="integratedMode" />
    </handlers>
  </system.webServer>

  <appSettings>
    <add key="AppRoot" value=".." />
    <add key="Log" value="../log/ironruby-rack.log" />
    <add key="RackEnv" value="development" />
  </appSettings>

  <runtime>
    <assemblyBinding xmlns="urn:schemas-microsoft-com:asm.v1">
      #{asm_redirect 'IronRuby',                   '1.0.0.0'}
      #{asm_redirect 'IronRuby.Libraries',         '1.0.0.0'}
      #{asm_redirect 'Microsoft.Scripting',        '1.0.0.0'}
      #{asm_redirect 'Microsoft.Dynamic',          '1.0.0.0'}
    </assemblyBinding>
  </runtime>
</configuration>
END_CONFIG
    end
  end
end
