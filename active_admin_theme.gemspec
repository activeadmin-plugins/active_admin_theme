# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'active_admin_theme/version'

Gem::Specification.new do |spec|
  spec.name          = "active_admin_theme"
  spec.version       = ActiveAdminTheme::VERSION
  spec.authors       = ["Igor Fedoronchuk", "Alex Sikorskiy"]
  spec.email         = ["igor.f@didww.com", "alex.s@didww.com"]
  spec.summary       = %q{Flat design for ActiveAdmin}
  spec.description   = %q{Flat design for activeadmin gem }
  spec.homepage      = "https://github.com/activeadmin-plugins/active_admin_theme"
  spec.license       = "MIT"

  spec.required_ruby_version = '>= 3.1.0'

  # Whitelist, not a reject list: a new directory in the repo does not
  # reach consumers until it is named here. The reject form needs a new
  # pattern every time the repo grows one, and that is how the 288 KB
  # README screenshot under img/ ended up published in the first place.
  spec.files         = `git ls-files -z -- lib app bin README.md LICENSE.txt`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activeadmin", ">= 3.0", "< 4.0"
end
