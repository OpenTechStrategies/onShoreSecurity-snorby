require File.expand_path('../boot', __FILE__)

# require 'rails/all'
require 'action_controller/railtie'
require 'dm-rails/railtie'
require 'action_mailer/railtie'
require 'rails/test_unit/railtie'
require 'will_paginate/array'
require 'dm-noisy-failures'
require 'dm_noisy_failures'
# If you have a Gemfile, require the gems listed there, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env) if defined?(Bundler)

module Snorby
  # Snorby Environment Specific Configurations
  raw_config = File.read("config/snorby_config.yml")
  CONFIG = YAML.load(raw_config)[Rails.env].symbolize_keys
  
  snmp_config = File.read("config/snmp_config.yml")
  CONFIG_SNMP = YAML.load(snmp_config)[Rails.env].symbolize_keys

  #Chef::Config[:node_name] = Chef::Config[:web_ui_client_name]
  #Chef::Config[:client_key] = Chef::Config[:web_ui_key] 
  Chef::Config[:node_name]  = "#{CONFIG[:chef_prefix]}-chef-webui"
  Chef::Config[:client_key] = "config/#{CONFIG[:chef_prefix]}-chef-webui.pem"
  Chef::Config[:environment]  = "#{CONFIG[:chef_environ]}"
  #By default :chef_server_url should be "http://localhost:4000"
  Chef::Config[:chef_server_url]="http://127.0.0.1:4000"

  # Default authentication to database
  unless CONFIG.has_key?(:authentication_mode)
    CONFIG[:authentication_mode] = "database"
  end
  
  class Application < Rails::Application
        
    # Custom directories with classes and modules you want to be autoloadable.
    config.autoload_paths += %W(#{config.root}/lib)

    PDFKit.configure do |config|
      config.wkhtmltopdf = Snorby::CONFIG[:wkhtmltopdf]
      config.default_options = {
          :page_size => 'Legal',
          :print_media_type => true
        }
    end
    
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
    
    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is America/Chicago.
    config.time_zone = 'America/Chicago'
    ENV['TZ'] = 'America/Chicago'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # JavaScript files you want as :defaults (application.js is always included).
    # config.action_view.javascript_expansions[:defaults] = %w(jquery rails)
    
    config.generators do |g|
      g.orm             :data_mapper
      g.template_engine :erb
      g.test_framework  :rspec
    end
    
    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    config.action_mailer.default_url_options = { :host => Snorby::CONFIG[:domain] }

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]
    
    # SSL
    # config.force_ssl = true
  end


#  if Snorby::CONFIG[:authentication_mode] == "ldap"
#    #delete "not null" property for encrypted_password
#    DataMapper.repository(:default).adapter.execute "ALTER TABLE snorby.users MODIFY COLUMN encrypted_password VARCHAR(128) CHARACTER SET utf8 COLLATE utf8_general_ci DEFAULT NULL"
#  else
#    DataMapper.repository(:default).adapter.execute "ALTER TABLE snorby.users MODIFY COLUMN encrypted_password VARCHAR(128) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL;"
#  end
  
end
