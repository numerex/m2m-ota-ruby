require 'rubygems'
require 'bundler/setup'
require 'test/unit'

$:.unshift File.expand_path('../lib', __FILE__)
require 'm2m-ota'
require "#{File.dirname(__FILE__)}/hexdump.rb"
