#!/usr/bin/env ruby
#-*- encoding: utf-8 -*-

require 'optparse'

require_relative 'step_parser'
require_relative 'confluence_step_outputter'
require_relative 'html_step_outputter'


# Parse command line
options = {}
opts = OptionParser.new do |opts|
  opts.banner = "Usage: cuke-steps.rb [options] <directories...>"

  opts.on("-o", "--output FILE", "Output to FILE") do |file|
    options[:file] = file
  end
  opts.on("-f", "--format FMT", "Select output format: cf, html") do |format|
    options[:format] = format
  end
end
opts.parse!(ARGV)

# Default output options
if options[:file] && !options[:format]
  options[:format] = options[:file].sub(/^.*\./, "")
end
if !options[:format]
  options[:format] = "html"
end
if options[:format] && !options[:file]
  options[:file] = "steps.#{options[:format]}"
end


# All other arguments are treated as input directories
dirs = ARGV
if dirs.size == 0
  puts "No source directories provided, use -h for help"
  exit 1
end

# Setup output
case options[:format]
when 'cf'
  output = ConfluenceStepOutputter.new(options[:file])
when 'html'
  output = HtmlStepOutputter.new(options[:file])
else
  puts "Unknown output format: #{options[:format]}"
  exit 1
end
puts "Writing output to file '#{options[:file]}'"


# Sort primarily by step type, secondarily by step definition
sorter = lambda do |a,b|
  if a[:type] == b[:type]
    a[:name].downcase <=> b[:name].downcase
  else
    weight = { "Given" => 1, "When" => 2, "Then" => 3, "Transform" => 4, "Before" => 5, "After" => 6, "AfterStep" => 7 }
    wa = weight[a[:type]]
    wb = weight[b[:type]]
    wa <=> wb
  end
end


# Read files and output
all_steps = []
output.header
dirs.each do |dir|
  dir = dir.sub(/\/+$/, "")
  s = StepParser.new
  Dir.glob("#{dir}/**/*.rb") do |file|
    s.read(file)
  end
  steps = s.steps
  all_steps += steps

  output.start_directory(dir)
  steps.sort!(&sorter)
  steps.each { |s| output.step(s) }
  output.end_directory
end

if dirs.size > 1
  output.start_all
  all_steps.sort!(&sorter)
  all_steps.each { |s| output.step(s) }
  output.end_all
end

output.footer
output.close
