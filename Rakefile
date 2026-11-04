require "bundler/gem_tasks"

desc "Build the dummy app's Tailwind CSS (npm CLI)"
task :assets do
  Dir.chdir("test/dummy") do
    unless Dir.exist?("node_modules")
      sh "npm #{ENV['CI'] ? 'ci' : 'install'} --no-audit --no-fund"
    end
    sh "npm run build"
  end
end

desc "Smoke test: every demo page renders with the theme (builds CSS first)"
task test: :assets do
  Dir["test/*_test.rb"].sort.each { |file| ruby file }
end

desc "Regenerate the README screenshot img/clock.png (needs Chrome)"
task :screenshot do
  ruby "test/screenshot.rb"
end

task default: :test
