require "net/http"
require "json"

url = "https://raw.githubusercontent.com/github/gemoji/master/db/emoji.json"

response = JSON.parse(Net::HTTP.get(URI(url)))

not_flags = response.reject { |e| e["category"] == "Flags" }

all_emoji = not_flags.flat_map { |e| e["aliases"] }.uniq.sort

denied_by_us = File.read("denylist.txt").split("\n")

emoji_we_care_about = all_emoji - denied_by_us

formatted = emoji_we_care_about.map { |e| "  #{e}" }.join("\n")

File.write("lgtm.rb", <<~RUBY)
  # This file is generated. See build.rb

  emoji = %w{
  #{formatted}
  }.sample

  print ":\#{emoji}:"
RUBY
