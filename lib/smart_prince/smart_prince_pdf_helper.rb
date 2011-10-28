module SmartPrincePdfHelper
  require 'smart_prince'
  # edit by rshua 2011/10/27
  module ClassMethods
=begin
  #application_controller.rb
  prince_default_config :stylesheets => ["common", "pdf"], :layout => "pdf", :template_type => ".html.erb"
=end    
    def prince_default_config(options = {})
      self.smart_prince_default_config[:stylesheets] = options[:stylesheets] || []
      self.smart_prince_default_config[:layout] = options[:layout] || false
      self.smart_prince_default_config[:template_type] = options[:template_type] || ".html.erb"
    end
  end
  
  # included
  def self.included(base)
    base.class_eval do
      def self.cattr_accessor_with_default(name, value = nil)
        cattr_accessor name
        self.send("#{name}=", value) if value
      end
      cattr_accessor_with_default :smart_prince_default_config, :stylesheets => [], :layout => false, :template_type => ".html.erb"
      alias_method_chain :render, :smart_prince
      extend ClassMethods
    end
  end
  
  def render_with_smart_prince(options = nil, *args, &block)
    if options.is_a?(Hash) && options.has_key?(:pdf)
      options[:name] ||= options.delete(:pdf)
      make_and_send_pdf(options.delete(:name), options)      
    else
      render_without_smart_prince(options, *args, &block)
    end
  end  
  
  private
  
  def make_pdf(options = {})
    options[:template] ||= File.join(controller_path, [action_name, self.class.smart_prince_default_config[:template_type]].join(""))
    prince = SmartPrince.new()
    # Sets style sheets on PDF renderer
    prince.style_sheets_config(self.class.smart_prince_default_config[:stylesheets], options[:stylesheets] ||= {})
    html_string = render_to_string(:template => options[:template], :layout => options[:layout] || self.class.smart_prince_default_config[:layout])
    # Make all paths relative, on disk paths...
    html_string.gsub!(".com:/", ".com/") # strip out bad attachment_fu URLs
    html_string.gsub!("src=\"", "src=\"#{RAILS_ROOT}/public")
    # Send the generated PDF file from our html string.
    prince.pdf_from_string(html_string)
  end
  
  def make_and_send_pdf(pdf_name, options = {})
    tmp_pdf_name = case pdf_judage_brower_type(request.env["HTTP_USER_AGENT"])
      when "IE"
        url_encode pdf_name
      when "Firefox"
        pdf_name
      when "Safari"
        pdf_name    
    else
      url_encode pdf_name
    end
    send_data(
              make_pdf(options),
              :filename => tmp_pdf_name + ".pdf",
              :type => 'application/pdf'
    ) 
  end
  
  # judge brower's type
  def pdf_judage_brower_type(http_user_agent)
    return "Firefox" if http_user_agent.include?("Firefox")
    return "Safari" if http_user_agent.include?("Safari")
    return "IE" if http_user_agent.include?("MSIE")
    return "IE"
  end 
  
end
