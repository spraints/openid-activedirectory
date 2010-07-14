require 'rubygems'
is_ironruby = defined?(RUBY_ENGINE) && (RUBY_ENGINE == 'ironruby')
unless is_ironruby
  require 'bundler'
  Bundler.setup
end
require 'sinatra'

get '/' do
  content_type :text
  'hello!'
end
