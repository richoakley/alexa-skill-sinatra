require 'rubygems' 
require 'bundler'

Bundler.require
Bundler.require :development if development?

require './app'
run Sinatra::Application