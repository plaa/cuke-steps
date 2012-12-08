#!/usr/bin/env ruby
#-*- encoding: utf-8 -*-

require 'cgi'
require 'fileutils'

class StepParser

  attr_reader :steps
  def initialize
    @steps = []
  end

  def read(file)
    @current_file = file
    @line_number = 0
    @lines = IO.read(file).split(/\r?\n/)
    parse_lines
  end


  private

  def next_line
    @line_number += 1
    @lines.shift
  end

  def unread(line)
    @line_number -= 1
    @lines.unshift(line)
  end

  def parse_lines
    @comments = []
    while not @lines.empty?

      line = next_line
      case line
      when /^ *#/
        @comments << line
      when /^(Given|When|Then|Before|After|AfterStep|Transform) /
        unread(line)
        parse_step
        @comments = []
      when /^\s+(Given|When|Then|Before|After|AfterStep|Transform) /
        puts "WARNING:  Indented step definition in file #{@current_file}:  #{line}"
        @comments = []
      else
        @comments = []
      end

    end
  end

  def parse_step
    type = parse_step_type(@lines.first)
    name = parse_step_name(@lines.first)
    line_number = @line_number + 1
    code = @comments
    line = ""
    while !@lines.empty? && !(line =~ /^end\s*$/)
      line = next_line
      code << line
    end
    @steps << { :type => type, :name => name, :filename => @current_file, :code => code, :line_number => line_number }
  end

  def parse_step_type(line)
    line.sub(/^([A-Za-z]+).*/, '\1')
  end

  def parse_step_name(line)
    line = line.sub(/^(Given|When|Then|Transform) +\/\^?(.*?)\$?\/.*/, '\1 \2')
    line = line.gsub('\ ', ' ')
    line
  end

end

class ConfluenceStepOutputter
  def initialize(file)
    @file = File.open(file, 'w')
    @previous_type = ""
  end

  def close
    @file.puts %(<p>&nbsp;</p>)
    @file.puts %(<p><em>Documentation generated #{Time.now}</em></p>)
    @file.close
  end

  def start_directory(dir)
    @file.puts %(<p>&nbsp;</p>)
    @file.puts "<h2>#{dir}</h2>"
    @previous_type = ""
  end

  def end_directory
    # No-op
  end

  def start_all
    @file.puts %(<p>&nbsp;</p>)
    @file.puts "<h2>All definitions alphabetically</h2>"
    @previous_type = ""
  end

  def end_all
    # No-op
  end

  def step(step)
    if @previous_type != step[:type]
      @file.puts %(<h3>#{step[:type]} definitions</h3>)
      @previous_type = step[:type]
    end
    @file.puts %(<ac:macro ac:name="expand">)
    @file.puts %( <ac:parameter ac:name="title">#{CGI.escapeHTML(step[:name])}</ac:parameter>)
    @file.puts %( <ac:rich-text-body>)
    # TODO: Add link to source repo or Jenkins workspace
    # <p><a href=".../#{CGI.escapeHTML(step[:filename])}" style="color: #888;">#{CGI.escapeHTML(step[:filename])}:#{step[:line_number]}</a></p>
    @file.puts %(  <p style="color: #888;">#{CGI.escapeHTML(step[:filename])}:#{step[:line_number]}</p>)
    @file.puts %(  <pre style="background-color: #ddd; padding-top: 1.2em;">)
    step[:code].each do |line|
      @file.puts %(   #{CGI.escapeHTML(line)})
    end
    @file.puts %(  </pre>)
    @file.puts %( </ac:rich-text-body>)
    @file.puts %(</ac:macro>)
  end

end

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


# All arguments are treated as input directories
# TODO: Make more configurable
DIRECTORIES = ARGV
puts "Scanning directories:"
DIRECTORIES.each { |dir| puts "  #{dir}" }


# Output to "steps.cf"
# TODO: Make outputter and output file configurable
puts "Writing output to steps.cf"
output = ConfluenceStepOutputter.new("steps.cf")


# Read files and output
all_steps = []
DIRECTORIES.each do |dir|
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

output.start_all
all_steps.sort!(&sorter)
all_steps.each { |s| output.step(s) }
output.end_all

output.close


