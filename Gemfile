source 'https://rubygems.org'

# Specify your gem's dependencies in active_admin_theme.gemspec
gemspec

group :development, :test do
  gem 'rake'
  gem 'sassc'
  # Screenshots. Ferrum is a pure-Ruby CDP client, so CI needs no Node
  # toolchain — only the Chrome that the runner already has. Rails itself is
  # not here: test/screens/dummy.rb generates an app that bundles its own.
  gem 'ferrum'
end
