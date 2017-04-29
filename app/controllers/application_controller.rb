require 'dm-rails/middleware/identity_map'
require 'net/ldap'
require 'devise_ldap_authenticatable'
require 'devise_ldap_authenticatable/strategy'
require 'devise_ldap_authenticatable/model'

class ApplicationController < ActionController::Base
  rescue_from DeviseLdapAuthenticatable::LdapException do |exception|
    render :text => exception, :status => 500
  end
  use Rails::DataMapper::Middleware::IdentityMap
  protect_from_forgery

  rescue_from CanCan::AccessDenied do |exception|
    flash[:error] = "Access denied."
    redirect_to root_url
  end

  rescue_from DataMapper::ObjectNotFoundError do |exception|
    render :file => "public/404.html", :status => 404
  end
  
  before_filter :authenticate_user!
  before_filter :user_setup
  before_filter :set_timezone

  def passthrough
    redirect_to !current_user.nil? ? current_user.root_page : url_for(:controller => 'page', :action => 'dashboard')
  end
  
  protected

    def set_timezone
      Time.zone = browser_timezone.nil? ? "UTC" : browser_timezone
    end

    def get_reduced_data(data, elements)
      d1 = data.first(elements)
      other = data.from(elements).map{|x| x[1]}.sum
      d1 << ["Others", other] if other>0
      d1
    end

    def get_treemap_data(elements_group=5, data)
      data_other = data.from(elements_group)
      data = data.first(elements_group).map{|x| {:name => x[0], :children => [{:name => x[0].truncate(30), :size => x[1].to_i}]} }
    
      if (data_other.length>0) 
        data << {:name => "Other", :children => get_treemap_data(elements_group, data_other)}
      end
      data    
    end


    def require_administrative_privileges
      return true if user_signed_in? && current_user.admin
      flash[:error] = "Do not have enough privileges to do that."
      redirect_to root_path
    end
    
    def check_sensor_dbversion_update
      return true if !Snorby::Worker.running? or !Snorby::Jobs.sensor_update_dbversion?
      flash[:error] = "The sensors are updating its rules version."
      redirect_to root_path
    end

    def user_setup
      if user_signed_in?
        if current_user.enabled
          User.current_user = current_user
          # set session filter for user
          session[:filter] = {} unless session[:filter]
          session[:rule_filter] = {} unless session[:rule_filter]
        else
          sign_out current_user
          redirect_to login_path, :notice => 'Your account has be disabled. Please contact the administrator.'
        end
      #else
      #  current_uri = request.env['PATH_INFO']
      #  routes = ["", "/", "/users/login"]
      #
      #  if current_uri && routes.include?(current_uri)
      #    redirect_to '/users/login' unless current_uri == "/users/login"
      #  else
      #    authenticate_user!
      #  end
      end
      
      # if Time.respond_to?(:zone)
      #   Time.zone = current_user.timezone
      # else
      #   Time.timezone = current_user.timezone
      # end
    end

    def set_metric(column_sym)
      case column_sym
      when :IPV4_SRC_ADDR 
        @src_metrics = get_reduced_data(@cache.src_metrics, 8)
      when :IPV4_DST_ADDR
        @dst_metrics = get_reduced_data(@cache.dst_metrics, 8)
      when :SENSOR
        @sensor_metrics = @cache.sensor_metrics(@range.to_sym)
      when :SIGNATURE
        @signature_metrics = get_reduced_data(@cache.signature_metrics, 8)
      when :SEVERITY
        @high   = @cache.severity_count(:high, @range.to_sym)
        @medium = @cache.severity_count(:medium, @range.to_sym)
        @low    = @cache.severity_count(:low, @range.to_sym)
      when :PROTOCOL
        @tcp    = @cache.protocol_count(:tcp, @range.to_sym)
        @udp    = @cache.protocol_count(:udp, @range.to_sym)
        @icmp   = @cache.protocol_count(:icmp, @range.to_sym)
      when :MAP        
        @map_data = Snorby::Geoip.latlong( (@cache.src_metrics|@cache.dst_metrics).map{|x| x[0]}.uniq )
      end
    end

    def set_table_metric(column_sym)
      case column_sym
      when :IPV4_SRC_ADDR 
        @table_metrics = @cache.src_metrics
      when :IPV4_DST_ADDR
        @table_metrics = @cache.dst_metrics
      when :SENSOR
        @table_metrics = []
        @cache.sensor_metrics(@range.to_sym).each do |sensor|
          @table_metrics << [sensor[:name], sensor[:data].sum]
        end
      when :SIGNATURE
        @table_metrics = @cache.signature_metrics
      when :SEVERITY
        @table_metrics = [
          ["high",    @cache.severity_count(:high, @range.to_sym).sum],
          ["medium",  @cache.severity_count(:medium, @range.to_sym).sum],
          ["low",     @cache.severity_count(:low, @range.to_sym).sum]
        ].sort{ |a,b| b[1] <=> a[1] }
      when :PROTOCOL
        @table_metrics = [
          ["tcp",     @cache.protocol_count(:tcp, @range.to_sym).sum],
          ["udp",     @cache.protocol_count(:udp, @range.to_sym).sum],
          ["icmp",    @cache.protocol_count(:icmp, @range.to_sym).sum]
        ].sort{ |a,b| b[1] <=> a[1] }
      end
    end

    def set_defaults
      case @range.to_sym
      when :last_24      
        @start_time = @now.yesterday.beginning_of_day + @now.yesterday.hour.hours #@now.yesterday.utc
        @end_time   = @now
        @cache = Cache.last_24(@start_time.utc, @end_time.utc)
      when :today
        @cache = Cache.today
        @start_time = @now.beginning_of_day
        @end_time = @now.end_of_day
      when :yesterday
        @cache = Cache.yesterday
        @start_time = (@now - 1.day).beginning_of_day
        @end_time   = (@now - 1.day).end_of_day
      when :before_1_yesterday
        @cache      = Cache.before_1_yesterday
        @start_time = (@now - 2.day).beginning_of_day
        @end_time   = (@now - 2.day).end_of_day
      when :before_2_yesterday
        @cache      = Cache.before_2_yesterday
        @start_time = (@now - 3.day).beginning_of_day
        @end_time   = (@now - 3.day).end_of_day
      when :before_3_yesterday
        @cache      = Cache.before_3_yesterday
        @start_time = (@now - 4.day).beginning_of_day
        @end_time   = (@now - 4.day).end_of_day
      when :before_4_yesterday
        @cache      = Cache.before_4_yesterday
        @start_time = (@now - 5.day).beginning_of_day
        @end_time   = (@now - 5.day).end_of_day
      when :week
        @cache = DailyCache.this_week
        @start_time = @now.beginning_of_week
        @end_time = @now.end_of_week
      when :last_week
        @cache = DailyCache.last_week
        @start_time = (@now - 1.day).end_of_day - 1.week
        @end_time = @now.yesterday.end_of_day
      when :month
        @cache = DailyCache.this_month
        @start_time = @now.beginning_of_month
        @end_time = @now.end_of_month
      when :last_month
        @cache = DailyCache.last_month
        @start_time = @now - 1.months
        @end_time = @now.yesterday.end_of_day
      when :quarter
        @cache = DailyCache.this_quarter
        @start_time = @now.beginning_of_quarter
        @end_time = @now.end_of_quarter
      when :last_quarter
        @cache = DailyCache.last_quarter
        @start_time = @now - 3.months
        @end_time = @now.yesterday.end_of_day
      when :year
        @cache = DailyCache.this_year
        @start_time = @now.beginning_of_year
        @end_time = @now.end_of_year
      when :last_year
        @cache = DailyCache.last_year
        @start_time = @now - 1.year
        @end_time = @now.yesterday.end_of_day
      else
        @cache = Cache.today
        @start_time = @now.beginning_of_day
        @end_time = @now.end_of_day
      end
 
      @cache = @cache.all(:sensor => Sensor.all.select{|s| can? :read, s})
    end

    def browser_timezone
      return nil if cookies[:tzoffset].blank?
      @browser_timezone ||= begin
      zone = cookies[:tzoffset].to_s
      ActiveSupport::TimeZone[zone]
      end
    end
end
