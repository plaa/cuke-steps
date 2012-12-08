# Outputter that generates Confluence markup

require 'cgi'
require 'fileutils'

class ConfluenceStepOutputter
  def initialize(file)
    @file = File.open(file, 'w')
    @previous_type = ""
  end

  def header
    # No-op
  end
  def footer
    @file.puts %(<p>&nbsp;</p>)
    @file.puts %(<p><em>Documentation generated #{Time.now}</em></p>)
  end

  def close
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
