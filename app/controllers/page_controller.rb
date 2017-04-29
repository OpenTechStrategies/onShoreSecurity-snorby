class PageController < ApplicationController

  helper_method :sort_column, :sort_direction, :sort_page
  include Snorby::Jobs::CacheHelper

  def dashboard

    @now = Time.zone.now
    @range = params[:range].blank? ? 'last_24' : params[:range]
    @load_all = params[:load_all].blank? ? false : (params[:load_all]=="true" || params[:load_all]=="1")

    set_defaults

    @new_tabs = Event::AGGREGATED_COLUMNS.reject{|k, v| current_user.dashboardTabs.map(&:column).include?(k.to_s)}.sort{|a1,a2| a1[1]<=>a2[1]}.to_a
    @axis     = Cache.count_hash(@range.to_sym).keys

    #This are neccesary for top counter 
    @high_bar   = @cache.severity_count(:high, @range.to_sym, true)
    @medium_bar = @cache.severity_count(:medium, @range.to_sym, true)
    @low_bar    = @cache.severity_count(:low, @range.to_sym, true)

    set_metric(:SIGNATURE)          #necessary for right column
    set_metric(:SENSOR)             #necessary for right column

    @sensors = @sensor_metrics.map{|x| [ x[:sid], x[:name], x[:data].sum, Sensor.first(:name => x[:name]) ]}

    @event_count       = @cache.all.map(&:event_count).sum

    @tabs = []

    if request.format  == :pdf
      #TODO for the future the pdf must reflect the openned tabs
      current_tabs = [
        DashboardTab.new(:column => "SENSOR"),
        DashboardTab.new(:column => "SIGNATURE"),
        DashboardTab.new(:column => "SEVERITY"),
        DashboardTab.new(:column => "PROTOCOL"),
        DashboardTab.new(:column => "IPV4_SRC_ADDR"),
        DashboardTab.new(:column => "IPV4_DST_ADDR")        
      ]
    else
      current_tabs = current_user.dashboardTabs(:order => [:position.asc])

      if current_tabs.length == 0
        current_user.dashboardTabs << DashboardTab.new(:column => "SENSOR")
        current_user.save?
        current_tabs = current_user.dashboardTabs(:order => [:position.asc])
      end    

      active_tab    = current_tabs.first(:column => session[:tab].to_s) unless session[:tab].nil?
      session[:tab] = current_tabs.first.column if active_tab.nil?
    end

    current_tabs.each do |tab|
      if (@load_all or (request.format  == :pdf) or (session[:tab].to_s == tab.column.to_s and session[:tab].to_s!="SIGNATURE" and session[:tab].to_s!="SENSOR"))
        set_metric(tab.column.to_sym)
      end
      @tabs << {:column => tab.column.to_sym, :name => Event::AGGREGATED_COLUMNS[tab.column.to_sym]} 
    end

    @classifications = Classification.all(:order => [:events_count.desc], :events_count.gt => 0)      
    @last_cache      = @cache.cache_time.in_time_zone unless @cache.cache_time.nil?
    @favers = User.all(:limit => 5, :order => [:favorites_count.desc])
    sigs = latest_five_distinct_signatures
    @recent_events = [];
    sigs.each{|s| @recent_events << Event.last(:sig_id => s) }



    respond_to do |format|
      format.html # { render :template => 'page/dashboard.pdf.erb', :layout => 'pdf.html.erb' }
      format.js
      format.pdf do
        render :pdf => "OnGuard SIM Report - #{@start_time.strftime('%A-%B-%d-%Y-%I-%M-%p')} - #{@end_time.strftime('%A-%B-%d-%Y-%I-%M-%p')}", :template => "page/dashboard.pdf.erb", :layout => 'pdf.html.erb', :stylesheets => ["pdf"]
      end
    end

  end

  def search
    #@json = Snorby::Search.json
    @filter = Hash.new
    items = Hash.new
    index = 0
    unless params[:new_filter].present?
      session[:filter].each do |k, v|
        v.each do |key, value|
          items[index] = {:column => k.to_s, :operator => value[:operator], :value => key.to_s, :enabled => true}
          index += 1
        end
      end
  end
      @filter = {:match_all => false, :items => items} unless items.blank?



  end

  def results

    if params.has_key?(:search) && !params[:search].blank?

      if params[:search].is_a?(String)
        @value ||= JSON.parse(params[:search])
        params[:search] = @value
      end

      session[:filter] = {}

      enabled_count = 0
      for item in params[:search] do
        x = item.last
        enabled = (x['enabled'] or x[:enabled]).to_s

        if !enabled.blank?
          enabled_count += 1 if enabled.to_s === "true"
        else
          enabled_count += 1 
        end
      end

      if enabled_count == 0
        redirect_to :back, :flash => {:error => "There was a problem parsing the search rules."}
      end

      params[:search].each do |key, value|

        next if !value[:enabled]

        if value[:column].to_sym == :start_time or value[:column].to_sym == :end_time
          value[:value] = Time.zone.at(value[:value].to_i)
        end
     
          if session[:filter][value[:column].to_sym] and session[:filter][value[:column].to_sym][value[:value]]
          session[:filter][value[:column].to_sym][value[:value]] = {:operator => value[:operator]}
        elsif session[:filter][value[:column].to_sym]
          session[:filter][value[:column].to_sym].merge! ({value[:value] => {:operator => value[:operator]}})
        elsif session[:filter]
          session[:filter].merge! ({value[:column].to_sym => {value[:value] => {:operator => value[:operator]}}})
        end
      end

      redirect_to events_path
  
    elsif params.has_key?(:add_search) and !params[:add_search].blank?

      params[:add_search] = [params[:add_search]] unless params[:add_search].is_a?(Array)

      params[:add_search].each do |item|

        if item[:column].to_sym == :start_time or item[:column].to_sym == :end_time
          item[:value] = Time.zone.at(item[:value].to_i)
        end
        if session[:filter][item[:column].to_sym] and session[:filter][item[:column].to_sym][item[:value]]
          session[:filter][item[:column].to_sym][item[:value]] = {:operator => item[:operator]}
        elsif session[:filter][item[:column].to_sym]
          session[:filter][item[:column].to_sym].merge! ({item[:value] => {:operator => item[:operator]}})
        elsif session[:filter]
          session[:filter].merge! ({item[:column].to_sym => {item[:value] => {:operator => item[:operator]}}})
        end
      end 

      redirect_to events_path

    elsif params.has_key?(:quick_search) && !params[:quick_search].blank?

      redirect_to events_path(:quick_search => params[:quick_search])

    elsif params.has_key?(:search_id) and !params[:search_id].blank?
       if params[:search_id]
        @search_object ||= params[:search_id]
       end
        params[:sort] = sort_column
        params[:direction] = sort_direction
        params[:classification_all] = true
        @search = (params.has_key?(:authenticity_token) ? true : false)
        @params = params.to_json
        @events = Event.sorty(params)
        @classifications ||= Classification.all
    else
      redirect_to :back, :flash => {
        :error => "There was a problem parsing the search rules."
      }
    end

  rescue ActionController::RedirectBackError
    redirect_to search_path, :flash => {
        :error => "There was a problem parsing the search rules."
      }
  end
  
def search_json
    render :json => Snorby::Search.json
  end
    

  def force_cache
    Snorby::Jobs.force_sensor_cache
    render :json => {
      :caching => Snorby::Jobs.caching?,
      :problems => Snorby::Worker.problems?,
      :running => Snorby::Worker.running?,
      :daily_cache => Snorby::Jobs.daily_cache?,
      :sensor_cache => Snorby::Jobs.sensor_cache?
    }
  end


  def cache_status
    render :json => {
      :caching => Snorby::Jobs.caching?,
      :problems => Snorby::Worker.problems?,
      :running => Snorby::Worker.running?,
      :daily_cache => Snorby::Jobs.daily_cache?,
      :sensor_cache => Snorby::Jobs.sensor_cache?
    }
  end

  def cluster
    @cluster = Snorby::Cluster.new
  end

  def add_tab
    @column = params[:id]
    user = User.current_user

    if !DashboardTab.first(:user => user, :column => @column.to_s)
      user.dashboardTabs << DashboardTab.new(:column => @column.to_s)
    end

    if user.save?
      @range = params[:range].blank? ? 'last_24' : params[:range]
      if params[:end_time].nil?
        @now = Time.zone.at(params[:end_time].to_i) 
      else
        @now = Time.zone.now
      end
      #applying filters
      set_defaults
      set_metric(@column.to_sym)
      @tab = {:column => @column.to_sym, :name => Event::AGGREGATED_COLUMNS[@column.to_sym]}
      
      if @column.to_sym != :MAP
        @axis   = Cache.count_hash(@range.to_sym).keys
      end
    else
      render :js => ""
    end
  end
  def delete_tab
    @column = params[:id]
    @range = params[:range].blank? ? 'last_1_hours' : params[:range]
    @end_time = params[:end_time].blank? ? Time.zone.now.to_i : params[:end_time]

    if User.current_user.dashboardTabs.length == 1
      render :js => ""
    else
      tab = User.current_user.dashboardTabs(:column => @column)
      tab.destroy
    end
  end

  def change_tab
    session[:tab] = params[:id].to_sym
    render :js => ""
  end

  def reorder_tab
    params[:tabs].each_with_index do |tab, i|
      DashboardTab.first(:user => current_user, :column => tab).update(:position => i)
    end
    render :js => ""
  end

  def del_filter
    vals    = []
    values  = params[:values]

    if params[:id].to_s == "all"
      session[:filter] = {}
    else
      if values.nil? or !values.respond_to?('each')
        values=[]
      end

      values << params[:value] unless params[:value].nil?

      values.each do |v|
        if params[:id].to_sym == :start_time or params[:id].to_sym == :end_time
          vals << DateTime.strptime(v, '%Y-%m-%d %H:%M:%S %z')
        else
          vals << v
        end
      end

      vals.each do |val|
        if session[:filter][params[:id].to_sym] and session[:filter][params[:id].to_sym][val]
          if session[:filter][params[:id].to_sym].count > 1
            session[:filter][params[:id].to_sym].delete(val)
          else
            session[:filter].delete(params[:id].to_sym)
          end
        elsif session[:filter][params[:id].to_sym]
          session[:filter][params[:id].to_sym].merge! ({ val => { :operator => "not" } })
        else
          session[:filter].merge! ({ params[:id].to_sym => { val => { :operator => "not" } } })
        end
      end
    end

    redirect_to events_path

  end

  private

  def set_defaults

    @now = Time.zone.now

    case @range.to_sym
    when :custom
      @cache = Cache.all(:ran_at.gte => @custom_start, :ran_at.lte => @custom_end)
      @start_time = Time.zone.parse(@custom_start).beginning_of_day
      @end_time = Time.zone.parse(@custom_end).end_of_day
    when :last_24

      @start_time = @now.yesterday
      @end_time = @now
      
      # Fix This
      # @start_time = @now.yesterday.beginning_of_day
      # @end_time = @now.end_of_day
      
      @cache = Cache.last_24(@start_time, @end_time)

    when :today
      @cache = Cache.today
      @start_time = @now.beginning_of_day
      @end_time = @now.end_of_day

    when :yesterday
      @cache = Cache.yesterday
      @start_time = (@now - 1.day).beginning_of_day
      @end_time = (@now - 1.day).end_of_day

    when :week
      @cache = DailyCache.this_week
      @start_time = @now.beginning_of_week
      @end_time = @now.end_of_week

    when :last_week
      @cache = DailyCache.last_week
      @start_time = (@now - 1.week).beginning_of_week
      @end_time = (@now - 1.week).end_of_week

    when :month
      @cache = DailyCache.this_month
      @start_time = @now.beginning_of_month
      @end_time = @now.end_of_month

    when :last_month
      @cache = DailyCache.last_month
      @start_time = (@now - 1.months).beginning_of_month
      @end_time = (@now - 1.months).end_of_month

    when :quarter
      @cache = DailyCache.this_quarter
      @start_time = @now.beginning_of_quarter
      @end_time = @now.end_of_quarter

    when :year
      @cache = DailyCache.this_year
      @start_time = @now.beginning_of_year
      @end_time = @now.end_of_year

    else
      @cache = Cache.today
      @start_time = @now.beginning_of_day
      @end_time = @now.end_of_day
    end

  end

  def sort_column
    return :timestamp unless params.has_key?(:sort)
    return params[:sort].to_sym if Event::SORT.has_key?(params[:sort].to_sym)
    :timestamp
  end
  
  def sort_direction
    %w[asc desc].include?(params[:direction].to_s) ? params[:direction].to_sym : :desc
  end

  def sort_page
    params[:page].to_i
  end

end
