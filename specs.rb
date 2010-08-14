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

      get '/login'
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
      get '/login'
    end

    it 'should not login' do
      last_request.session['current_user'].should be_nil
    end
  end

  context 'openid requests' do
    context 'when logged in' do
      it 'should handle user requests (TODO: fill in)'
    end
    context 'when not logged in' do
      context 'for the user page' do
        before do
          header 'Accept', 'text/html, application/xhtml+xml, application/xrds+xml'
          get '/user/TESTDOMAIN/testuser'
        end

        it 'should return XRDS' do
          last_response.headers['Content-type'].should == 'application/xrds+xml'
        end

        it 'should return server URI' do
          last_response.body.should =~ %r{<URI>http://example.org/server</URI>}
        end
      end

      it 'should handle initial server request' do
        post '/server',
          'openid.mode' => 'associate',
          'openid.assoc_type' => 'HMAC-SHA1',
          'openid.ns' => 'http://specs.openid.net/auth/2.0',
          'openid.session_type' => 'DH-SHA1',
          'openid.dh_consumer_public' => 'blah'
        # This is a lame test, but it's all I've got for now.
        last_response.status.should == 200
      end

      it 'should show decision page' do
        #get '/server', :more => 'params'
      end

      it 'should redirect back to consumer when user says yes'
        #post '/server/decide', :yes => 'yes'

      it 'should acknowledge the no'
        #post '/server/decide', :no => 'no'

      it 'should redirect the user to the login page with a return url (TODO: fill in)'
    end
  end
end
