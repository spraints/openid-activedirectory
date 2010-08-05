require 'rubygems'
ENV['BUNDLE_GEMFILE'] ||= File.expand_path(__FILE__ + '/../Gemfile')
require 'bundler'
Bundler.setup
require 'sinatra'
require 'haml'
require 'sinatra/url_for'
require 'openid'

configure do
  enable :sessions
end

class ActiveDirectoryUser
  attr_reader :domain, :user
  def initialize(*name)
    case name.size
    when 1
      @domain, @user = name.first.split('\\')
    when 2
      @domain, @user = name
    else
      raise "Invalid name spec: #{name.inspect}"
    end
  end
  def to_s
    "#{@domain}\\#{@user}"
  end
  def ==(other)
    other.domain == self.domain && other.user == self.user
  rescue
    false
  end
end

helpers do
  def current_user
    current_user_from_session || current_user_from_aspnet
  end

  def login
    request.session['current_user'] = current_user
  end

  def login!
    request.session['current_user'] = nil
    login
  end

  def current_user_from_session
    request.session['current_user']
  end

  def current_user_from_aspnet
    httpContextClass = System::AppDomain.current_domain.get_assemblies.select { |a| a.full_name =~ /^System.Web,/ }.first.get_type('System.Web.HttpContext').to_class
    ActiveDirectoryUser.new httpContextClass.current.user.identity.name
  rescue => e
    @error = e
    nil
  end

  def my_url
    user_url current_user
  end

  def user_url user
    "/user/#{user.domain}/#{user.user}"
  end

  def xrds_url user
    user_url(user) + "/xrds"
  end

  def render_xrds *types
    types = types.collect { |uri| "<Type>#{uri}</Type>" }.join("\n")
    <<END_XRDS
<?xml version="1.0" encoding="UTF-8"?>
<xrds:XRDS
    xmlns:xrds="xri://$xrds"
    xmlns="xri://$xrd*($v*2.0)">
  <XRD>
    <Service priority="0">
      #{types}
      <URI>#{url_for '/server', :full}</URI>
    </Service>
  </XRD>
</xrds:XRDS>
END_XRDS
  end

  def user_xrds user
    render_xrds OpenID::OPENID_2_0_TYPE, OpenID::OPENID_1_0_TYPE, OpenID::SREG_URI
  end
end

get '/' do
  redirect '/login'
end

get '/login' do
  login!
  if current_user
    redirect my_url
  else
    haml :not_logged_in
  end
end

get '/user/:domain/:username' do
  @requested_user = ActiveDirectoryUser.new params[:domain], params[:username]
  if request.accept.include? 'application/xrds+xml'
    content_type 'application/xrds+xml'
    user_xrds @requested_user
  elsif @requested_user == current_user
    haml :me
  else
    haml :not_me
  end
end
