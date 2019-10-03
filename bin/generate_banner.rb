#!/usr/bin/env ruby

require 'rmagick'
require 'pp'

src = ARGV[0]
dst = ARGV[1]
week = ""

pp src
pp dst

if (src =~ %r[long-reads/\d+/([\d\-]+)\.html\.md])
    week = $1.sub('-', '/')
else
    puts "Unable to parse #{src}"
    exit 1
end

pp week

background = Magick::Pixel.from_hsla(rand(0.0..360.0), rand(0.0..100.0), 100)

canvas = Magick::Image.new(3000, 3000){
    self.background_color = background
    self.gravity = Magick::CenterGravity
}


gc = Magick::Draw.new{
    self.gravity = Magick::CenterGravity
    self.pointsize = 250
    self.undercolor = background
    self.fill = "white"
    self.font = "Courier-BoldOblique"
}

canvas.annotate(gc, 0, 0, 0, 0, "Weekend Long Reads\n\n#{week}")
canvas.write(dst)