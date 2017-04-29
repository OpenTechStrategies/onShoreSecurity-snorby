class SnmpsController < ApplicationController
  respond_to :html, :xml, :json, :js, :csv
  
  helper_method :sort_column, :sort_direction

  def index
    if params[:sensor_id].nil?
      @sensor = nil
    elsif !Sensor.get(params[:sensor_id]).domain
      raise ActionController::RoutingError.new('Not Found')
    else
      @sensor = Sensor.get(params[:sensor_id])
      raise CanCan::AccessDenied if cannot?(:read, @sensor)
    end
      
    @now = Time.now
    #@now = Time.zone.now
    @range = params[:range].blank? ? 'last_3_hours' : params[:range]
    @load_all = params[:load_all].blank? ? false : (params[:load_all]=="true" || params[:load_all]=="1")

    set_defaults

    @axis = Snmp.count_hash(@range.to_sym).keys

    virtual_sensors = if @sensor 
      @sensor.virtual_sensors.select{|s| can? :read, s}
    else
      Sensor.get(1).virtual_sensors.select{|s| can? :read, s}
    end

    #Filtramos los eventos snmp sobre los que tengamos permisos
    @snmp = @snmp.all(:sensor => virtual_sensors)

    #@last_snmp = @snmp.sort{|a, b| a.timestamp <=> b.timestamp}.last
    @last_snmp = @snmp.all(:order => [:timestamp]).last

    #graficas de tiempo para la parte de high, medium y low
    @high_snmp    = @snmp.severity_count(:high, @range.to_sym, true)
    @medium_snmp  = @snmp.severity_count(:medium, @range.to_sym, true)
    @low_snmp     = @snmp.severity_count(:low, @range.to_sym, true)
    @snmp_count   = @high_snmp.sum + @medium_snmp.sum + @low_snmp.sum

    #Manage active tabs
    @tabs = []
    current_tabs = current_user.snmpTabs(:order => [:position.asc])

    if current_tabs.length == 0
      #There are no tabs. We specify CPU tab at least
      current_user.snmpTabs << SnmpTab.new(:column => "CPU")
      current_user.save
      current_tabs = current_user.snmpTabs(:order => [:position.asc])
    end

    active_tab    = current_tabs.first(:column => session[:snmp_tab].to_s)
    session[:snmp_tab] = current_tabs.first.column if active_tab.nil?            #if the active tab is not presented at the list of tabs

    current_tabs.each do |tab|
      if (@load_all or (request.format  == :pdf) or session[:snmp_tab].to_s == tab.column.to_s)
        set_metric(tab.column.to_sym)
      end
      @tabs << {:column => tab.column.to_sym, :name => Snmp::AGGREGATED_COLUMNS[tab.column.to_sym]}        
    end

    @new_tabs = Snmp::AGGREGATED_COLUMNS.reject{|k, v| current_user.snmpTabs.map(&:column).include?(k.to_s)}.sort{|a1,a2| a1[1]<=>a2[1]}.to_a

    @metrics = @snmp.metrics

    #TRAPS
    @traps   = Trap.all(:sensor => virtual_sensors, :order => [:timestamp.desc], :limit => 5)
    
    respond_to do |format|
      format.html
      format.js
      format.pdf do
        render :pdf => "OnGuard SIM Snmp Report - #{@start_time.strftime('%A-%B-%d-%Y-%I-%M-%p')} - #{@end_time.strftime('%A-%B-%d-%Y-%I-%M-%p')}", :template => "snmps/index.pdf.erb", :layout => 'pdf.html.erb', :stylesheets => ["pdf"]
      end
    end
  end

  def search
    @sensors = Sensor.all(:domain => true).select{|s| (can? :read, s) and !s.is_root?}.sort{|s1, s2| s1.sensor_name <=> s2.sensor_name}
  end
  
  def results    
    params[:sort] = sort_column
    params[:direction] = sort_direction

    params[:search] = Hash.new unless params[:search]
    params[:search][:snmp_type] = "snmp_statistics"

    @snmps = Snmp.sorty(params)
  end

  def add_tab
    @column = params[:id]
    user = User.current_user

    if !SnmpTab.first(:user => user, :column => @column.to_s)
      user.snmpTabs << SnmpTab.new(:column => @column.to_s)
    end

    if user.save
      @range = params[:range].blank? ? 'last_24' : params[:range]
      if params[:end_time].nil?
        @now = Time.at(params[:end_time].to_i)
      else
        @now = Time.now
      end

      #applying filters
      set_defaults
      set_metric(@column.to_sym)   #hay que activarlo
      @tab = {:column => @column.to_sym, :name => Snmp::AGGREGATED_COLUMNS[@column.to_sym]}
      @axis = Cache.count_hash(@range.to_sym).keys

    else
      render :js => ""
    end
  end

  def delete_tab
    @column   = params[:id]
    @range    = params[:range].blank? ? 'last_1_hours' : params[:range]
    @end_time = params[:end_time].blank? ? Time.now.to_i : params[:end_time]

    if User.current_user.snmpTabs.length == 1
      render :js => ""
    else
      tab = User.current_user.snmpTabs(:column => @column)
      tab.destroy
    end
  end

  def change_tab
    session[:snmp_tab] = params[:id].to_sym
    render :js => ""
  end

  def reorder_tab
    params[:tabs].each_with_index do |tab, i|
      SnmpTab.first(:user => current_user, :column => tab).update(:position => i)
    end
    render :js => ""
  end

  private

  def set_metric(column_sym)
    case column_sym
    when :CPU 
      @cpu_metric = @snmp.snmp_metrics("1.3.6.1.4.1.2021.11.11.0", @range.to_sym)
    when :MEMORY
      @memory_metric = @snmp.snmp_metrics("1.3.6.1.4.1.39483.1.2.2.4.1.2.9.115.104.101.108.108.116.101.115.116.1", @range.to_sym)
    when :LOAD
      @load_metric = @snmp.snmp_metrics("1.3.6.1.4.1.2021.10.1.3.2", @range.to_sym)
    when :HDD
      @hdd_metric = @snmp.snmp_metrics("1.3.6.1.4.1.2021.9.1.9.1", @range.to_sym)
    when :SEVERITIES
      @high_snmp    = @snmp.severity_count(:high, @range.to_sym)
      @medium_snmp  = @snmp.severity_count(:medium, @range.to_sym)
      @low_snmp     = @snmp.severity_count(:low, @range.to_sym)
    end
  end
  
  def set_defaults
    case @range.to_sym
    when :last_3_hours
      @start_time = @now - 3.hours
      @end_time = @now
      @snmp = Snmp.last_3_hours(@start_time.utc, @end_time.utc)
    when :last_24
      @start_time = @now.yesterday
      @end_time = @now
      @snmp = Snmp.last_24(@start_time.utc, @end_time.utc)
    when :today
      @start_time = @now.beginning_of_day
      @end_time = @now.end_of_day
      @snmp = Snmp.today
    when :yesterday
      @start_time = (@now - 1.day).beginning_of_day
      @end_time = (@now - 1.day).end_of_day
      @snmp = Snmp.yesterday
    when :week
      @start_time = @now.beginning_of_week
      @end_time = @now.end_of_week
      @snmp = Snmp.this_week
    when :last_week
      @start_time = @now - 1.week
      @end_time = @now
      @snmp = Snmp.last_week
    when :month
      @start_time = @now.beginning_of_month
      @end_time = @now.end_of_month
      @snmp = Snmp.this_month
    when :last_month
      @start_time = @now - 1.months
      @end_time = @now
      @snmp = Snmp.last_month
    when :quarter
      @start_time = @now.beginning_of_quarter
      @end_time = @now.end_of_quarter
      @snmp = Snmp.this_quarter
    when :last_quarter
      @start_time = @now - 3.months
      @end_time = @now
      @snmp = Snmp.last_quarter
    when :year
      @start_time = @now.beginning_of_year
      @end_time = @now.end_of_year
      @snmp = Snmp.this_year
    when :last_year
      @start_time = @now - 1.year
      @end_time = @now
      @snmp = Snmp.last_year
    else
      @start_time = @now.beginning_of_day
      @end_time = @now.end_of_day
      @snmp = Snmp.today
    end

    @snmp = @snmp.all(:sensor => Sensor.all.select{|s| can? :read, s})

  end  
  
  def sort_column
    return :timestamp unless params.has_key?(:sort)
    return params[:sort].to_sym if Snmp::SORT.has_key?(params[:sort].to_sym)
  end
  
  def sort_direction
    %w[asc desc].include?(params[:direction].to_s) ? params[:direction].to_sym : :desc
  end
  
end
