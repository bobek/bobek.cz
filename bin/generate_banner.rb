#!/usr/bin/env ruby

require 'rmagick'
require 'pp'

dst = ARGV[0]
week = ''

if dst =~ %r{long-reads/\d+/([\d\-]+)\.png}
  parsed = Regexp.last_match(1)
  week = parsed.sub('-', '/')
  dst = dst.sub('.png', '')
else
  puts "Unable to parse #{src}"
  exit 1
end

pp dst
pp week

background = Magick::Pixel.from_hsla(rand(0.0..360.0), rand(0.0..100.0), 100)

canvas = Magick::Image.new(3000, 3000) do |img|
  img.background_color = background
  img.gravity = Magick::CenterGravity
end

canvas_small = Magick::Image.new(3000, 1000) do |img|
  img.background_color = background
  img.gravity = Magick::CenterGravity
end

gc = Magick::Draw.new do |d|
  d.gravity = Magick::CenterGravity
  d.pointsize = 250
  d.undercolor = background
  d.fill = 'white'
  d.font = 'Courier-BoldOblique'
end

canvas.annotate(gc, 0, 0, 0, 0, "Weekend Long Reads\n\n#{week}")
canvas_small.annotate(gc, 0, 0, 0, 0, "Weekend Long Reads\n\n#{week}")

canvas.write("#{dst}-og.png")
canvas_small.write("#{dst}.png")
