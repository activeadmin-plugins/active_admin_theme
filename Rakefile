require "bundler/gem_tasks"

desc "Compile the theme against ActiveAdmin and check the result"
task :css do
  ruby "test/css_check.rb"
end

desc "Capybara integration test: the server clock renders + ticks (needs Chrome)"
task :test do
  ruby "test/clock_test.rb"
end

desc "Regenerate the neutral README screenshot img/clock.png (needs Chrome)"
task :screenshot do
  ruby "test/screenshot.rb"
end

# css only: :test needs the Rails/Capybara stack the Gemfile excludes on
# Ruby 3.1 (the gem's own minimum) plus a local Chrome. Run `rake test`
# explicitly where both are available; CI names its tasks per job anyway.
task default: :css
