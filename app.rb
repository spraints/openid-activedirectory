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
    ActiveDirectoryUser.new httpContextClass.current.user.identity.name
  rescue => e
    @error = e
    nil
  end

  def current_user_from_params
    return nil unless
      development?                   &&
      (domain   = params[:domain]  ) &&
      (username = params[:username])
    ActiveDirectoryUser.new domain, username
  end

  def my_url
    user_url current_user
  end

  def user_url user
    url_for("/user/#{user.domain}/#{user.user}", :full)
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
    @server ||= OpenID::Server::Server.new(OpenID::Store::Filesystem.new(File.expand_path(__FILE__ + '/../db/provider')), url_for('/server', :full))
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

  def add_sreg request, response
    sregreq = OpenID::SReg::Request.from_openid_request request
    return if sregreq.nil?
    raise 'TODO -- show real user info'
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

get '/server' do
  be_server
end
post '/server' do
  be_server
end
helpers do
  def be_server

  @openid_request = server.decode_request(params)
  unless @openid_request
    return redirect '/'
  end
  if @openid_request.kind_of?(OpenID::Server::CheckIDRequest)
    identity = @openid_request.identity
    if @openid_request.id_select
      if @openid_request.immediate
        @openid_response = @openid_request.answer(false)
      elsif logged_in?
        identity = my_url
      else
        session[:req] = @openid_request
        return haml :decision
      end
    end
    if @openid_response
      nil
    elsif authorized?(identity, @openid_request.trust_root)
      @openid_response = @openid_request.answer true, nil, identity
      add_sreg @openid_request, openid_response
      add_pape @openid_request, openid_response
    elsif @openid_request.immediate
      @openid_response = @openid_request.answer false, url_for('/server', :full)
    else
      session[:req] = @openid_request
      return haml :decision
    end
  else
    @openid_response = server.handle_request @openid_request
  end
  render_openid_response

  end
end

post '/server/decide' do
  @openid_request = session.delete :req
  params[:yes] or
    return redirect @openid_request.cancel_url
  id_to_send = params[:id_to_send]
  identity = @openid_request.identity
  if @openid_request.id_select
    content_type :text
    return 'No, really, you are stuck. I am not going to authorize this request. Use your real account page.'
  end
  approve @openid_request.trust_root
  @openid_response = @openid_request.answer true, nil, identity
  add_sreg @openid_request, @openid_response
  add_pape @openid_request, @openid_response
  render_openid_response
end
