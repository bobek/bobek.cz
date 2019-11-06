#!/usr/bin/env ruby

require 'pp'
require 'yaml'

raw = ARGF.read

meta = YAML::load(raw)
source = raw.gsub(/---(.|\n)*---/, '')

puts %Q(Subject: #{meta['title']}
From: longreads@bobek.cz
To: #{ENV['MC_DEST']}

\# #{meta['title']}

You can find the online version and archive at [https://www.bobek.cz/long-reads/](https://www.bobek.cz/long-reads/).

#{source}
)

