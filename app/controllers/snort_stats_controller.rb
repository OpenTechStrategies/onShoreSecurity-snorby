class SnortStatsController < ApplicationController
  
  helper_method :sort_column, :sort_direction
  
  before_filter :require_administrative_privileges, :only => [:names, :update_enabled_name, :update_text_name, :update_measure_unit]

  def index
    params[:sort] = sort_column
    params[:direction] = sort_direction
    @stats = SnortStat.sorty(params)
    
    respond_to do |format|
      format.html
      format.js
    end
  end

  def names
    @snort_names = SnortStatName.all
  end
  
  def search
    @sensors = Sensor.all(:domain => true).select{|s| (can? :read, s) and !s.is_root?}
                                          .sort{|s1, s2| s1.sensor_name <=> s2.sensor_name}  
  end
  
  def info
    if params[:sensor_id]
      @sensor = Sensor.get!(params[:sensor_id])
      raise DataMapper::ObjectNotFoundError if !@sensor.domain
      raise CanCan::AccessDenied if cannot?(:read, @sensor)
    else
      @sensor = Sensor.get(1)
    end
    
    if !@sensor.virtual_sensor
      @sensors = @sensor.virtual_sensors.select{|s| can? :read, s}
    end
    
    @now = Time.zone.now
    @range = params[:range].blank? ? 'last_3_hours' : params[:range]
    
    set_defaults
    
    virtual_sensors = @sensor.virtual_sensors

    @stats = @stats.all(:sensor => virtual_sensors)
    
    
    if @sensors
      @metrics = @stats.metrics(@range.to_sym)
    else
      @metrics = @stats.metrics_by_sensor(@range.to_sym)
    end

    if @metrics.first and @metrics.first[:data].last
      @axis = @metrics.first[:data].last[:range].join(',')
    end
    #if @metrics.first and @metrics.first[:data].last and @range == 'last_3_hours'
    #  # take only half of the items for axis
    #  index = 0
    #  @axis = @metrics.first[:data].last[:range].map{|x| index += 1; index % 2 == 1 ? x : "' '"}.join(',')
    #elsif @metrics.first and @metrics.first[:data].last
    #  @axis = @metrics.first[:data].last[:range].join(',')
    #end
  end
  
  def update_enabled_name
    @snort_stat_name = SnortStatName.get(params[:snort_name_id])
    @snort_stat_name.update!(:enable => params[:enable]) if @snort_stat_name
    render :text => @snort_stat_name.enable
  end

  def update_text_name
    @snort_stat_name = SnortStatName.get(params[:id])
    @snort_stat_name.update!(:text_name => params[:text_name]) if @snort_stat_name
    render :text => @snort_stat_name.text_name
  end

  def update_measure_unit
    @snort_stat_name = SnortStatName.get(params[:id])
    @snort_stat_name.update!(:measure_unit => params[:measure_unit]) if @snort_stat_name
    render :text => @snort_stat_name.measure_unit
  end

  private
  
  def sort_column
    return :timestamp unless params.has_key?(:sort)
    return params[:sort].to_sym if SnortStat::SORT.has_key?(params[:sort].to_sym)
    :timestamp
  end
  
  def sort_direction
    %w[asc desc].include?(params[:direction].to_s) ? params[:direction].to_sym : :desc
  end
  
  def set_defaults
    case @range.to_sym
    when :last_3_hours
      
      @start_time = @now - 3.hours
      @end_time = @now
      @stats = SnortStat.last_3_hours(@start_time, @end_time)

    when :last_24

      @start_time = @now.yesterday
      @end_time = @now
      @stats = SnortStat.last_24(@start_time, @end_time)
      
    when :today
      
      @start_time = @now.beginning_of_day
      @end_time = @now.end_of_day
      @stats = SnortStat.today
    
    when :yesterday
      
      @start_time = (@now - 1.day).beginning_of_day
      @end_time = (@now - 1.day).end_of_day
      @stats = SnortStat.yesterday
      
    when :week
      
      @start_time = @now.beginning_of_week
      @end_time = @now.end_of_week
      @stats = SnortStat.this_week
    
    when :last_week
      @stats = SnortStat.last_week
      @start_time = (@now - 1.week).beginning_of_week
      @end_time = (@now - 1.week).end_of_week
  
    when :month
      
      @start_time = @now.beginning_of_month
      @end_time = @now.end_of_month
      @stats = SnortStat.this_month

    when :last_month
      @stats = SnortStat.last_month
      @start_time = (@now - 1.months).beginning_of_month
      @end_time = (@now - 1.months).end_of_month  

    when :quarter

      @start_time = @now.beginning_of_quarter
      @end_time = @now.end_of_quarter
      @stats = SnortStat.this_quarter
            
    when :last_quarter
      @start_time = @now - 3.months
      @end_time = @now
      @stats = SnortStat.last_quarter

    when :year
      
      @start_time = @now.beginning_of_year
      @end_time = @now.end_of_year
      @stats = SnortStat.this_year

    when :last_year
      @start_time = @now - 1.year
      @end_time = @now
      @stats = SnortStat.last_year
  
    else
      
      @start_time = @now.beginning_of_day
      @end_time = @now.end_of_day
      @stats = SnortStat.today
      
    end  
  end

end
