require 'rubygems'
ENV['BUNDLE_GEMFILE'] ||= File.expand_path(__FILE__ + '/../Gemfile')
require 'bundler'
Bundler.setup :spec, :default
require 'app'
require 'rack/test'

# Ensure these things exist, even when we're not in IronRuby.
module System ; class AppDomain ; end ; end

describe 'openid-activedirectory' do
  include Rack::Test::Methods
  def app
    Sinatra::Application
  end

  context 'home page' do
    before do
      get '/'
    end

    it 'should redirect' do
      last_response.status.should == 302
    end

    it 'should redirect to login page' do
      last_response.headers["Location"].should == '/login'
    end
  end

  context 'login page when aspnet has a user' do
    before do
      mock_aspnet = mock('asp.net')
      System::AppDomain.stub!(:current_domain).and_return(mock_aspnet)
      mock_aspnet.stub!(:get_assemblies).and_return([mock_aspnet])
      mock_aspnet.stub!(:full_name).and_return('System.Web, blah blah blah')
      mock_aspnet.stub!(:get_type).and_return(mock_aspnet)
      mock_aspnet.stub!(:to_class).and_return(mock_aspnet)
      mock_aspnet.stub!(:current).and_return(mock_aspnet)
      mock_aspnet.stub!(:user).and_return(mock_aspnet)
      mock_aspnet.stub!(:identity).and_return(mock_aspnet)
      mock_aspnet.stub!(:name).and_return("DOMAIN\\USER")

      @session = {}
      get '/login', 'rack.session' => @session
    end

    it 'should login' do
      last_request.session['current_user'].should == ActiveDirectoryUser.new("DOMAIN", "USER")
    end

    it 'should redirect' do
      last_response.status.should == 302
    end

    it "should redirect to user's home page" do
      last_response.headers['Location'].should == 'http://example.org/user/DOMAIN/USER'
    end
  end

  context 'login page when aspnet has no user' do
    before do
      @session = {}
      get '/login', 'rack.session' => @session
    end

    it 'should not login'
    it 'should logout if previously logged in'
  end

  context 'openid requests' do
    context 'when logged in' do
      it 'should handle user requests'
    end
    context 'when not logged in' do
      it 'should handle server requests'
      it 'should redirect the user to the login page with a return url'
    end
  end
end
