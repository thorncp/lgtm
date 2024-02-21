require "fileutils"
require "json"

require "bundler/inline"

gemfile do
  source "https://rubygems.org"
  gem "http", "4.4.1"
  gem "rubyzip", require: "zip"
end

VERSION = "1.3.2"

url = "https://raw.githubusercontent.com/github/gemoji/master/db/emoji.json"

response = JSON.parse(HTTP.get(url))

not_flags = response.reject { |e| e["category"] == "Flags" }

all_emoji = not_flags.flat_map { |e| e["aliases"] }.uniq.sort

denied_by_us = File.read("denylist.txt").split("\n")

emoji_we_care_about = all_emoji - denied_by_us

formatted = emoji_we_care_about.map { |e| "  #{e}" }.join("\n")

script = <<~RUBY
  # This script is generated. See build.rb at https://github.com/thorncp/lgtm
  # rather than updating here.

  emoji = %w{
  #{formatted}
  }.sample

  print ":\#{emoji}:"
RUBY

template = File.read("template.plist")

plist = template
  .sub("$VERSION$", VERSION)
  .sub("$SCRIPT$", script)

File.open("workflow/info.plist", "w") do |f|
  f.write(plist)
end

FileUtils.rm_rf("lgtm.alfredworkflow")

Zip::File.open("lgtm.alfredworkflow", Zip::File::CREATE) do |zip|
  Dir.children("workflow").each do |file|
    zip.add(file, "workflow/#{file}")
  end
end
