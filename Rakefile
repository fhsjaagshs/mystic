#!/usr/bin/env ruby

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new 'spec'

# s = eval(File.read(Dir.glob("*.gemspec").first))
# app_name = s.name
# gem_name = "#{s.name}-#{s.version}.gem"
#
# task :clean do
#   `[ -f #{gem_name} ] && rm #{gem_name}`
# end
#
# task :build do
#   puts "Building '#{app_name}'..."
#   `gem build -q #{app_name}.gemspec`
# end
#
# task :install do
#   puts "Uninstalling currently installed '#{app_name}'..."
#   `gem uninstall -q --force #{gem_name}`
#   puts "Installing '#{app_name}'..."
#   `gem install -q --ignore-dependencies --local #{gem_name}`
# end
#
# task :push do
#   Rake::Task["clean"].invoke
#   Rake::Task["build"].invoke
#   puts "Pushing '#{app_name}' to rubygems..."
#   `gem push #{gem_name}`
# end
#
# task :validate do
#   `git diff --name-only --cached`.strip.split("\n").each do |fpath|
#     puts fpath unless `ruby -wc #{fpath}`.strip == "Syntax OK"
#   end
# end
#
# task :default do
#   Rake::Task["clean"].invoke
#   Rake::Task["build"].invoke
#   Rake::Task["install"].invoke
#   Rake::Task["clean"].invoke
# end