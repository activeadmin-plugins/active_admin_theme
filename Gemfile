source 'https://rubygems.org'

# Specify your gem's dependencies in active_admin_theme.gemspec

# Run against an unreleased ActiveAdmin, such as a branch with the layout hooks:
#   ACTIVEADMIN_PATH=../activeadmin bundle exec rake test
#   ACTIVEADMIN_BRANCH=extensible-layout bundle exec rake test
if ENV["ACTIVEADMIN_PATH"]
  gem "activeadmin", path: ENV["ACTIVEADMIN_PATH"]
elsif ENV["ACTIVEADMIN_BRANCH"]
  gem "activeadmin", github: ENV.fetch("ACTIVEADMIN_REPO", "senid231/activeadmin"), branch: ENV["ACTIVEADMIN_BRANCH"]
end
gemspec

# Run against an unreleased ActiveAdmin, such as a branch with the layout hooks:
#   ACTIVEADMIN_PATH=../activeadmin bundle exec rake test
#   ACTIVEADMIN_BRANCH=extensible-layout bundle exec rake test
if ENV["ACTIVEADMIN_PATH"]
  gem "activeadmin", path: ENV["ACTIVEADMIN_PATH"]
elsif ENV["ACTIVEADMIN_BRANCH"]
  gem "activeadmin", github: ENV.fetch("ACTIVEADMIN_REPO", "senid231/activeadmin"), branch: ENV["ACTIVEADMIN_BRANCH"]
end

# Dummy ActiveAdmin 4 app (test/dummy): importmap + propshaft, Tailwind CSS
# built with the npm CLI. It hosts the Capybara tests and the screenshot
# scripts.
group :development, :test do
  gem 'rake'
  gem 'rails', '~> 8.0'
  gem 'propshaft'
  gem 'importmap-rails'
  gem 'sqlite3'
  gem 'puma'
  gem 'capybara'
  gem 'cuprite'
end
