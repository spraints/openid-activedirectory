require 'rubygems'
ENV['BUNDLE_GEMFILE'] ||= File.expand_path(__FILE__ + '/../Gemfile')
require 'bundler'
Bundler.setup
require 'sinatra'
require 'haml'

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
    "/user/#{current_user.domain}/#{current_user.user}"
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
  if @requested_user == current_user
    haml :me
  else
    haml :not_me
  end
end
