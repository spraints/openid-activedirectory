require 'rubygems'
require 'bundler'
Bundler.setup
require 'sinatra'

get '/' do
  content_type :text
  'hello!'
end
