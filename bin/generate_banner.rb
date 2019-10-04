#!/usr/bin/env ruby

require 'rmagick'
require 'pp'

src = ARGV[0]
dst_dir = ARGV[1]
dst = ''
week = ''

pp src
pp dst_dir

if src =~ %r{long-reads/\d+/([\d\-]+)\.html\.md}
  parsed = $1
  week = parsed.sub('-', '/')
  dst = File.join(dst_dir, parsed)
else
  puts "Unable to parse #{src}"
  exit 1
end

pp dst
pp week

background = Magick::Pixel.from_hsla(rand(0.0..360.0), rand(0.0..100.0), 100)

canvas = Magick::Image.new(3000, 3000) do
  self.background_color = background
  self.gravity = Magick::CenterGravity
end

canvas_small = Magick::Image.new(3000, 1000) do
  self.background_color = background
  self.gravity = Magick::CenterGravity
end

gc = Magick::Draw.new do
  self.gravity = Magick::CenterGravity
  self.pointsize = 250
  self.undercolor = background
  self.fill = 'white'
  self.font = 'Courier-BoldOblique'
end

canvas.annotate(gc, 0, 0, 0, 0, "Weekend Long Reads\n\n#{week}")
canvas_small.annotate(gc, 0, 0, 0, 0, "Weekend Long Reads\n\n#{week}")

canvas.write("#{dst}-og.png")
canvas_small.write("#{dst}.png")
