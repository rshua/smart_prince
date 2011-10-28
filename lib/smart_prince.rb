# PrinceXML Ruby interface. 
# http://www.princexml.com
# USAGE
# -----------------------------------------------------------------------------
#   prince = SmartPrince.new()
#   html_string = render_to_string(:template => 'some_document')
#   send_data(
#     princely.pdf_from_string(html_string),
#     :filename => 'some_document.pdf'
#     :type => 'application/pdf'
#   )
#
$:.unshift(File.dirname(__FILE__))
require 'logger'
require 'smart_prince/rails'

class SmartPrince
  VERSION = "1.0.0" unless const_defined?("VERSION")
  
  attr_accessor :exe_path, :style_sheets, :log_file, :logger

  # Initialize method
  #
  def initialize()
    # Finds where the application lives, so we can call it.
#    @exe_path = `which prince`.chomp
    @exe_path = self.respond_to?(:windows?) && windows? ? "C:\\Program Files\\Prince\\Engine\\bin\\prince" : "/usr/local/bin/prince"
    raise "Cannot find prince command-line app in $PATH" if @exe_path.length == 0
    @style_sheets = ''
#    @log_file = "#{Rails.root}/log/prince.log"
    @log_file = "#{rails3? ? Rails.root : RAILS_ROOT}/log/prince.log"
    @logger = rails3? ? Rails.logger : Logger.new(@log_file)
  end
  
  # Sets stylesheets...
  # Can pass in multiple paths for css files.
  #
  def add_style_sheets(*sheets)
    for sheet in sheets.flatten do
      @style_sheets << " -s #{stylesheet_file_path sheet.to_s} "
    end
  end
  
  def delete_style_sheets(*sheets)
    for sheet in sheets do
      @style_sheets.delete(" -s #{stylesheet_file_path sheet.to_s } ")
    end
  end
  
  def style_sheets_config(*sheets)
    sheets.last[:add] ||= []
    sheets.first << sheets.last[:add].collect(&:to_s)
    add_style_sheets sheets.first.flatten
    delete_style_sheets sheets.last[:delete] ||= []
  end
  
  def stylesheet_file_path(stylesheet)
    stylesheet = stylesheet.to_s.gsub(".css", "")
    File.join(RAILS_ROOT, "public/stylesheets", "#{stylesheet}.css")
  end
  
  # Returns fully formed executable path with any command line switches
  # we've set based on our variables.
  def exe_path
    # Add any standard cmd line arguments we need to pass
    @exe_path << " --input=html --server --log=#{@log_file} "
    @exe_path << @style_sheets
    return @exe_path
  end
  
  # Makes a pdf from a passed in string.
  # Returns PDF as a stream, so we can use send_data to shoot
  # it down the pipe using Rails.
  def pdf_from_string(string)
    path = self.exe_path()
    # Don't spew errors to the standard out...and set up to take IO 
    # as input and output
    path << ' --silent - -o -'
    # Show the command used...
    logger.info "\n\nPRINCE XML PDF COMMAND"
    logger.info path
    logger.info ''
    # Actually call the prince command, and pass the entire data stream back.
    pdf = IO.popen(path, "w+")
    pdf.binmode if(windows?)
    pdf.puts(string)
    pdf.close_write
    result = pdf.gets(nil)
    pdf.close_read
    return result
  end
  
  def windows?
    !(RUBY_PLATFORM =~ /win32|mswin|mingw/).nil?
  end
  
  def rails3?
    Rails::VERSION::MAJOR == 3 
  end
  
  def logger=(logger)
    rails3? ? Rails.logger : Logger.new(File.join(RAILS_ROOT, logger))
  end
  
  def logger_file=(file)
    @logger_file = File.join(rails3? ? Rails.root : RAILS_ROOT, file) 
  end  
  
end