# encoding: UTF-8

require 'bundler'
#Bundler::GemHelper.install_tasks

require 'rake/testtask'

desc 'Default: run tests.'
task :default => :test

Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.libs << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end
