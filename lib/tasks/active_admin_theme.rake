namespace :active_admin_theme do
  desc "Write the machine-specific theme @import (active_admin_theme.generated.css) next to the Tailwind entry file; run it in every build, and git-ignore the generated file"
  task :css, [:entry] do |_task, args|
    require "active_admin_theme/css_import"
    entry = args[:entry] || "app/assets/stylesheets/active_admin.css"
    changes = ActiveAdminTheme::CssImport.write(entry)
    if changes.empty?
      puts "#{entry}: up to date"
    else
      changes.each { |file, result| puts "#{file == :entry ? entry : ActiveAdminTheme::CssImport.generated_path(entry)}: #{result}" }
    end
  end
end
