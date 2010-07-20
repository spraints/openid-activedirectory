require 'rubygems'
ENV['BUNDLE_GEMFILE'] ||= File.expand_path(__FILE__ + '/../Gemfile')
require 'bundler'
Bundler.setup
require 'sinatra'
require 'haml'

helpers do
  def current_user
    System::Web::HttpContext.current.user.identity.name
  rescue
    nil
  end
end

get '/' do
  @user = current_user
  if @user.nil? || @user.empty?
    haml :not_logged_in
  else
    return redirect "/#{@user}"
  end
end

get '/:username' do
  @requested_user = params[:username]
  if @requested_user == current_user
    haml :me
  else
    haml :not_me
  end
end
