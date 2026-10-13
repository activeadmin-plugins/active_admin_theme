source 'https://rubygems.org'

# Specify your gem's dependencies in active_admin_theme.gemspec
gemspec

group :development, :test do
  gem 'rake'
  gem 'sassc'
end

# Dummy ActiveAdmin app (test/dummy) that hosts the Capybara integration test
# (`rake test`) and sources the neutral README screenshot. Sprockets +
# sassc-rails is the pipeline AA 3.x targets (it emits `//= require` directives
# and SCSS). Rails 8 needs Ruby >= 3.2, so keep these out of the 3.1 bundle —
# `rake css` still runs on 3.1 without them.
if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('3.2')
  group :development, :test do
    gem 'rails', '~> 8.0'
    gem 'sprockets-rails'
    gem 'sassc-rails'
    gem 'sqlite3'
    gem 'puma'
    gem 'capybara'
    gem 'cuprite'
  end
end
