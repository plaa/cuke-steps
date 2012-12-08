# Outputter that generates HTML markup
# Feel free to customize the below code for your needs

require 'cgi'
require 'fileutils'

class HtmlStepOutputter
  
  def initialize(file)
    @file = File.open(file, 'w')
    @previous_type = ""
    @id_number = 0
  end
  
  # HTML file header - customize as needed
  def header
    @file.puts <<-eos
      <!DOCTYPE html>
      <html>
      <head>
      <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
      <title>Cucumber step documentation</title>
      <style>
      .stepdefs {
        font-size: smaller;
      }
      .stepdefs li {
        margin-bottom: 0.25em;
        list-style-type: none;
      }
      .stepdefs li:before {
        content: "\u00BB ";
        font-size: larger;
        padding-right: 0.3em;
      }
      .stepdef {
        color: #111;
        text-decoration: none;
      }
      .extrainfo {
        display: none;
        overflow: hidden; /* Fixes jumping issue in jQuery slideToggle() */
      }
      </style>
      <script src="http://ajax.googleapis.com/ajax/libs/jquery/1.8.3/jquery.min.js"></script>
      </head>
      <body>
    eos
  end
  
  def footer
    @file.puts <<-eos
      </ul>
      <p>&nbsp;</p>
      <p><em>Documentation generated #{Time.now}</em></p>
      </body>
      </html>
    eos
  end

  
  def close
    @file.close
  end

  def start_directory(dir)
    @file.puts %(</ul>) if @previous_type != ""
    @file.puts %(<p>&nbsp;</p>)
    @file.puts %(<h2>Step definitions in #{dir}/</h2>)
    @previous_type = ""
  end

  def end_directory
    # No-op
  end

  def start_all
    @file.puts %(</ul>)
    @file.puts %(<p>&nbsp;</p>)
    @file.puts %(<h2>All definitions alphabetically</h2>)
    @previous_type = ""
  end

  def end_all
    # No-op
  end

  def step(step)
    if @previous_type != step[:type]
      @file.puts %(</ul>) if @previous_type != ""
      @file.puts %(<h3>#{step[:type]} definitions</h3>)
      @file.puts %(<ul class="stepdefs">)
      @previous_type = step[:type]
    end

    id = new_id
    @file.puts %(<li>)
    @file.puts %(  <a href="#" onclick="$('##{id}').slideToggle(); return false;" class="stepdef">#{CGI.escapeHTML(step[:name])}</a>)
    @file.puts %(  <div id="#{id}" class="extrainfo">)
    # TODO: Add link to source repo or Jenkins workspace
    # <p><a href=".../#{CGI.escapeHTML(step[:filename])}" style="color: #888;">#{CGI.escapeHTML(step[:filename])}:#{step[:line_number]}</a></p>
    @file.puts %(    <p style="color: #888;">#{CGI.escapeHTML(step[:filename])}:#{step[:line_number]}</p>)
    @file.puts %(      <pre style="background-color: #ddd; padding-top: 1.2em;">)
    step[:code].each do |line|
      @file.puts %(   #{CGI.escapeHTML(line)})
    end
    @file.puts %(      </pre>)
    @file.puts %(  </div>)
    @file.puts %(</li>)
  end
  
  private
  
  def new_id
    @id_number += 1
    "id#{@id_number}"
  end

end
