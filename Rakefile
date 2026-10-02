require "bundler/gem_tasks"

desc "Compile the theme against ActiveAdmin and check the result"
task :css do
  ruby "test/css_check.rb"
end

task default: :css
