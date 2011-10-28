require 'smart_prince/smart_prince_pdf_helper'

Mime::Type.register 'application/pdf', :pdf

ActionController::Base.send(:include, SmartPrincePdfHelper)