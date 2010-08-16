require 'rubygems'
ENV['BUNDLE_GEMFILE'] ||= File.expand_path(__FILE__ + '/../Gemfile')
require 'bundler'
Bundler.setup
require 'sinatra'
require 'haml'
require 'sinatra/url_for'
require 'openid'
require 'openid/store/filesystem'
require 'openid/extensions/sreg'
require 'openid/extensions/pape'

configure do
  enable :sessions
end

class ActiveDirectoryUser
  attr_reader :domain, :username
  def initialize(windows_identity)
    @domain, @username = windows_identity.name.split('\\')
  end
  def fq_user
    "#{@domain}\\#{@username}"
  end
  def to_s
    fq_user
  end
  def ==(other)
    other.domain == self.domain && other.username == self.username
  rescue
    false
  end
end

class FakeActiveDirectoryUser < ActiveDirectoryUser
  def initialize(domain, username)
    @domain      = domain
    @username    = username
  end
end

helpers do
  def logged_in?
    ! current_user.nil?
  end

  def current_user
    current_user_from_session || current_user_from_aspnet || current_user_from_params
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
    ActiveDirectoryUser.new httpContextClass.current.user.identity
  rescue => e
    @error = e
    nil
  end

  def current_user_from_params
    return nil unless
      development?                   &&
      (domain   = params[:domain]  ) &&
      (username = params[:username])
    FakeActiveDirectoryUser.new domain, username
  end

  def my_url
    user_url current_user
  end

  def user_url user
    case user
    when ActiveDirectoryUser
      url_for("/user/#{user.domain}/#{user.username}", :full)
    else
      nil
    end
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

  def server
    @server ||= create_server
  end

  def create_server
    data_path = File.expand_path(__FILE__ + '/../db/provider')
    store = OpenID::Store::Filesystem.new(data_path)
    server_root = url_for('/server', :full)
    OpenID::Server::Server.new(store, server_root)
  end

  def authorized?(identity_url, trust_root)
    return logged_in? && identity_url == my_url && approved?(trust_root)
  end

  def approved? trust_root
    return (session[:approvals] || []).include? trust_root
  end

  def approve trust_root
    nil # todo
  end

  def render_openid_response
    content_type :text
    if @openid_response.needs_signing
      signed_response = server.signatory.sign @openid_response
    end
    web_response = server.encode_response @openid_response
    case web_response.code
    when OpenID::Server::HTTP_OK
      return web_response.body
    when OpenID::Server::HTTP_REDIRECT
      redirect web_response.headers['location']
    else
      status 400
      return web_response.body
    end
  end

  def add_pape request, response
    papereq = OpenID::PAPE::Request.from_openid_request request
    return if papereq.nil?
    paperesp = OpenID::PAPE::Response.new
    paperesp.nist_auth_level = 0 # we don't even do auth at all!
    response.add_extension paperesp
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
  @requested_user = FakeActiveDirectoryUser.new params[:domain], params[:username]
  if request.accept.include? 'application/xrds+xml'
    content_type 'application/xrds+xml'
    user_xrds @requested_user
  elsif @requested_user == current_user
    haml :me
  else
    haml :not_me
  end
end

get '/server' do
  be_server
end
post '/server' do
  be_server
end
helpers do
  def be_server

  @openid_request = server.decode_request(params) or
    return redirect '/'
  @sreg_request = OpenID::SReg::Request.from_openid_request @openid_request
  if @openid_request.kind_of?(OpenID::Server::CheckIDRequest)
    if @openid_request.id_select || @openid_request.identity != my_url
      return haml :login_required
    elsif !@sreg_request && authorized?(@openid_request.identity, @openid_request.trust_root)
      @openid_response = @openid_request.answer true, nil, @openid_request.identity
      add_sreg @openid_request, @openid_response
      add_pape @openid_request, @openid_response
    elsif @openid_request.immediate
      @openid_response = @openid_request.answer false, url_for('/server', :full)
    else
      return haml :decision
    end
  else
    @openid_response = server.handle_request @openid_request
  end
  render_openid_response

  end
end

def decode_decision params
  decision = Object.new
  def decision.params= x
    @params = x
  end
  def decision.trust?
    @params[:decision] == 'trust'
  end
  decision.params = params
  decision
end

post '/server/decide' do
  decision = decode_decision params
  @openid_request = server.decode_request(params)
  @sreg_request   = OpenID::SReg::Request.from_openid_request @openid_request
  if @openid_request.id_select
    return haml :login_required
  end
  unless decision.trust?
    return redirect @openid_request.cancel_url
  end
  identity = @openid_request.identity
  approve @openid_request.trust_root
  @openid_response = @openid_request.answer true, nil, identity
  if @sreg_request # 'trust' implies sreg is OK. See views/decision.haml
    sreg_response = OpenID::SReg::Response.extract_response @sreg_request,
      'nickname' => current_user.fq_user,
      'fullname' => 'Test Full Name',
      'email'    => 'test@example.org'
    @openid_response.add_extension sreg_response
  end
  add_pape @openid_request, @openid_response
  render_openid_response
end
