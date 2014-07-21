require 'rubygems' 
require 'bundler'

Bundler.require
Bundler.require :development if development?

require "sinatra"
require "json"
require 'open-uri'

require './app'
run Sinatra::Application