# Renders the PR comment: one row per scenario, before on the left, after on
# the right. Images are referenced by URL — nothing is committed to the repo.
#
#   ruby test/screens/comment.rb --before tmp/screens/before --after tmp/screens/after \
#        --url-prefix https://github.com/owner/repo/releases/download/screens/pr-51-
require "json"
require "optparse"

options = { before: "tmp/screens/before", after: "tmp/screens/after", url_prefix: "" }
OptionParser.new do |opts|
  opts.on("--before DIR")     { |v| options[:before] = v }
  opts.on("--after DIR")      { |v| options[:after] = v }
  opts.on("--url-prefix URL") { |v| options[:url_prefix] = v }
  opts.on("--base REF")       { |v| options[:base] = v }
end.parse!

def index(dir)
  path = File.join(dir, "index.json")
  File.exist?(path) ? JSON.parse(File.read(path), symbolize_names: true) : []
end

before = index(options[:before]).to_h { |s| [s[:name], s] }
after  = index(options[:after])

puts "<!-- theme-screens -->"
puts "## Screens"
puts
puts "Every scenario shot twice against the same ActiveAdmin and the same dummy " \
     "admin: once with the theme as it is on `#{options[:base] || "the base branch"}`, " \
     "once with the theme from this PR. Nothing is committed — the images are " \
     "release assets."
puts

changed = []
unchanged = []

after.each do |shot|
  next unless shot[:file]
  pair = before[shot[:name]]
  (pair && pair[:digest] == shot[:digest] ? unchanged : changed) << [shot, pair]
end

if changed.empty?
  puts "This PR does not change any of the #{after.size} scenarios."
else
  changed.each do |shot, pair|
    puts "### #{shot[:name]}"
    puts
    puts shot[:why] if shot[:why]
    puts
    puts "| before | after |"
    puts "|---|---|"
    b = pair&.dig(:file) ? "![before](#{options[:url_prefix]}before-#{pair[:file]})" : "_not shot_"
    puts "| #{b} | ![after](#{options[:url_prefix]}after-#{shot[:file]}) |"
    puts
  end
end

unless unchanged.empty?
  puts "<details><summary>Unchanged by this PR (#{unchanged.size})</summary>"
  puts
  unchanged.each { |shot, _| puts "- #{shot[:name]}" }
  puts
  puts "</details>"
  puts
end

failures = after.select { |s| s[:error] }
unless failures.empty?
  puts "> [!WARNING]"
  puts "> #{failures.size} scenario(s) could not be shot, so they are not compared here:"
  failures.each { |s| puts "> - `#{s[:name]}` — #{s[:error]}" }
end
