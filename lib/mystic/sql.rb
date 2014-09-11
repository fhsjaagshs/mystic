#!/usr/bin/env ruby

file_folder = File.dirname(File.absolute_path(__FILE__))
Dir.glob(file_folder + "/sql/**/*.rb", &method(:require))