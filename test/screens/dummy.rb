# Generates a throwaway Rails app with ActiveAdmin installed, so the
# screenshots are taken against ActiveAdmin's real markup instead of a
# hand-written approximation.
#
# The app only produces markup. The theme is not wired through its asset
# pipeline: test/screens/shoot.rb compiles the theme with sassc and swaps it in
# at screenshot time, which keeps this app free of sassc-rails and of any
# opinion about how a host project builds its assets.
#
#   ruby test/screens/dummy.rb [path]     # default: tmp/screens-dummy
require "bundler"
require "fileutils"
require "tmpdir"

# Outside the repository on purpose: ruby/setup-ruby writes a .bundle/config
# into the working directory, and bundler walks up from wherever it is run, so
# an app generated under tmp/ inherits a lockfile that does not describe it and
# resolves in local mode.
APP = File.expand_path(ARGV[0] || File.join(Dir.tmpdir, "active-admin-theme-screens"), Dir.pwd)

# This script is run from `rake screens`, i.e. from inside this gem's bundle.
# Everything below must escape it: the generated app has its own Gemfile and
# must resolve against that. with_unbundled_env restores the environment as it
# was before bundler touched it — clearing a list of BUNDLE_* variables by hand
# misses whatever the CI Ruby action added, and the symptom is bundler quietly
# resolving in local mode and failing to find gems that are simply not fetched.
def unbundled
  defined?(Bundler) ? Bundler.with_unbundled_env { yield } : yield
end

def sh(command, chdir: Dir.pwd)
  puts "  $ #{command}"
  unbundled { system(command, chdir: chdir, exception: true) }
end

# Run with the current interpreter rather than via PATH: on a machine with more
# than one Ruby, the `rails` on PATH can belong to a different installation than
# the one running this script.
def ruby_sh(*arguments, chdir: Dir.pwd)
  puts "  $ ruby #{arguments.join(" ")}"
  unbundled { system(Gem.ruby, *arguments, chdir: chdir, exception: true) }
end

def write(relative, contents)
  path = File.join(APP, relative)
  FileUtils.mkdir_p(File.dirname(path))
  File.write(path, contents)
end

if File.directory?(APP)
  puts "dummy: reusing #{APP}"
else
  puts "dummy: generating #{APP}"
  FileUtils.mkdir_p(File.dirname(APP))

  # Install the generator outside this gem's bundle and resolve its path in the
  # child, which is also unbundled — resolving it here would find the railties
  # vendored for this gem, which is not on the load path once the bundle is
  # gone. --conservative is a no-op when a Rails is already installed.
  ruby_sh File.join(RbConfig::CONFIG["bindir"], "gem"),
          "install", "rails", "--conservative", "--no-document"
  ruby_sh "-e", 'load Gem.bin_path("railties", "rails")', "--", "new", APP,
          "--asset-pipeline=sprockets", "--skip-git", "--skip-bootsnap", "--skip-jbuilder",
          "--skip-action-mailbox", "--skip-action-text", "--skip-action-cable",
          "--skip-active-storage", "--skip-hotwire", "--skip-test", "--skip-system-test",
          "--skip-kamal", "--skip-solid", "--skip-ci", "--skip-rubocop", "--skip-brakeman",
          "--skip-dev-gems", "--skip-docker", "--quiet"

  # `--asset-pipeline=sprockets` installs the gem but, since Rails 7, no longer
  # writes the manifest sprockets-rails refuses to boot without.
  FileUtils.mkdir_p(File.join(APP, "app/assets/stylesheets"))
  FileUtils.mkdir_p(File.join(APP, "app/assets/javascripts"))
  write "app/assets/config/manifest.js", <<~JS
    //= link_directory ../stylesheets .css
    //= link_directory ../javascripts .js
  JS

  File.open(File.join(APP, "Gemfile"), "a") do |gemfile|
    gemfile.puts
    gemfile.puts %(gem "activeadmin", "~> 3.0")
    gemfile.puts %(gem "sassc-rails")
  end

  sh "bundle install --quiet", chdir: APP
  sh "bin/rails generate active_admin:install --skip-users --quiet", chdir: APP
end

# --- Content -----------------------------------------------------------------
# Enough of an admin to exercise everything the theme touches: an index table
# with pagination, filters, batch actions and scopes; a form; a show page; and a
# menu deep enough to have a second-level flyout with a long label.

write "db/migrate/20260101000000_create_screens_schema.rb", <<~RUBY
  class CreateScreensSchema < ActiveRecord::Migration[7.2]
    def change
      create_table :authors do |t|
        t.string :name
        t.timestamps
      end
      create_table :posts do |t|
        t.string :title
        t.text :body
        t.boolean :published, default: false
        t.date :published_on
        t.references :author
        t.timestamps
      end
      create_table :settings do |t|
        t.string :key
        t.string :value
        t.timestamps
      end
    end
  end
RUBY

# Ransack 4 requires an explicit allowlist per model; without it the filter
# sidebar raises and ActiveAdmin quietly redirects to the dashboard.
RANSACK = <<~RUBY
    def self.ransackable_attributes(_auth = nil) = column_names
    def self.ransackable_associations(_auth = nil) = reflect_on_all_associations.map { |a| a.name.to_s }
RUBY

write "app/models/author.rb", <<~RUBY
  class Author < ApplicationRecord
    has_many :posts
  #{RANSACK}end
RUBY

write "app/models/post.rb", <<~RUBY
  class Post < ApplicationRecord
    belongs_to :author, optional: true
    scope :published, -> { where(published: true) }
    scope :drafts, -> { where(published: false) }
  #{RANSACK}end
RUBY

write "app/models/setting.rb", <<~RUBY
  class Setting < ApplicationRecord
  #{RANSACK}end
RUBY

write "app/admin/authors.rb", <<~RUBY
  ActiveAdmin.register Author do
    permit_params :name
  end
RUBY

write "app/admin/posts.rb", <<~RUBY
  ActiveAdmin.register Post do
    permit_params :title, :body, :published, :published_on, :author_id

    scope :all, default: true
    scope :published
    scope :drafts

    filter :title
    filter :author
    filter :published_on

    index do
      selectable_column
      id_column
      column :title
      column :author
      column :published
      column :published_on
      actions
    end
  end
RUBY

# The menu is what most of the header findings are about: a top-level item with
# a dropdown, a second-level item with its own flyout, and a label long enough
# to show what an unbounded panel does.
write "app/admin/settings.rb", <<~RUBY
  ActiveAdmin.register Setting do
    permit_params :key, :value
    menu parent: "System", label: "Configuration Settings"
  end
RUBY

write "app/admin/components.rb", <<~RUBY
  ActiveAdmin.register_page "Background Job Queue Monitor" do
    menu parent: ["System", "Components"]
    content { para "placeholder" }
  end
RUBY

write "app/admin/delivery.rb", <<~RUBY
  ActiveAdmin.register_page "Outbound SMS Delivery Receipt Reconciliation Settings" do
    menu parent: ["System", "Components"]
    content { para "placeholder" }
  end
RUBY

write "app/admin/audit.rb", <<~RUBY
  ActiveAdmin.register_page "Audit Log" do
    menu parent: "System"
    content { para "placeholder" }
  end
RUBY

write "db/seeds.rb", <<~RUBY
  Author.destroy_all
  Post.destroy_all
  Setting.destroy_all

  authors = 4.times.map { |i| Author.create!(name: "Author \#{i + 1}") }
  60.times do |i|
    Post.create!(title: "Post number \#{i + 1}", body: "Body \#{i + 1}",
                 published: i.even?, published_on: Date.new(2026, 1, 1) + i,
                 author: authors[i % authors.size])
  end
  3.times { |i| Setting.create!(key: "setting_\#{i}", value: "value_\#{i}") }
RUBY

# ActiveAdmin's install generator leaves an authentication hook pointing at a
# method this app does not have; the screenshots are of a logged-in admin.
initializer = File.join(APP, "config/initializers/active_admin.rb")
contents = File.read(initializer)
contents = contents.sub(/^\s*config\.authentication_method.*$/, "  config.authentication_method = false")
contents = contents.sub(/^\s*config\.current_user_method.*$/,  "  config.current_user_method = false")
File.write(initializer, contents)

sh "bin/rails db:drop db:create db:migrate db:seed", chdir: APP

puts "dummy: ready at #{APP}"
