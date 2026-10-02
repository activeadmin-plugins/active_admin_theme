require "bundler/gem_tasks"

desc "Compile the theme against ActiveAdmin and check the result"
task :css do
  ruby "test/css_check.rb"
end

task default: :css

desc "Shoot the screen gallery for this branch and for its base"
task :screens, [:base] do |_task, args|
  base = args[:base] || ENV.fetch("BASE_REF", "origin/master")
  app  = ENV.fetch("DUMMY_APP", File.expand_path("tmp/screens-dummy"))
  out  = ENV.fetch("SCREENS_OUT", File.expand_path("tmp/screens"))
  theme = "app/assets/stylesheets/wigu/active_admin_theme.scss"

  ruby "test/screens/dummy.rb #{app}"

  # The base revision of the theme, compiled from git rather than from a
  # checkout, so the dummy app is built once and reused for both runs.
  before_root = File.join(out, "before-theme", "wigu")
  mkdir_p before_root
  File.write(File.join(before_root, "active_admin_theme.scss"), `git show #{base}:#{theme}`)

  ruby "test/screens/shoot.rb --app #{app} --out #{out}/after  --theme-root app/assets/stylesheets"
  ruby "test/screens/shoot.rb --app #{app} --out #{out}/before --theme-root #{File.join(out, "before-theme")}"
end
