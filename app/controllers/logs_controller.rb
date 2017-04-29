class LogsController < ApplicationController

  before_filter :require_administrative_privileges
  
  helper_method :sort_column, :sort_direction
  
  def index
    params[:sort] = sort_column
    params[:direction] = sort_direction
    @logs = Log.sorty(params)
    
    respond_to do |format|
      format.html
      format.js
    end
  end

  def show
    return if params[:sensor_id].nil?

    @sensor = Sensor.get(params[:sensor_id])

    return if !@sensor.virtual_sensor

    file = @sensor.short_name + "-" + @sensor.ipdir + ".log"

    @log_content = `tail -n 100 #{Snorby::CONFIG[:remote_logs_path]}/#{file}`.split("\n")

    render :layout => false

  end

  def show_sensor
    return if params[:sensor_id].nil?
    @sensor = Sensor.get(params[:sensor_id])

    return if !@sensor.virtual_sensor

    @filter_search = params[:search].nil? ? nil : params[:search][:text].gsub(/[;\/'\\]/, "")
    
    file = @sensor.short_name + "-" + @sensor.ipdir + ".log"
    if @filter_search.nil?
      @log_content = `tail -n 350 #{Snorby::CONFIG[:remote_logs_path]}/#{file}`.split("\n").reverse
    else
      @log_content = `tail -n 350 #{Snorby::CONFIG[:remote_logs_path]}/#{file} | grep -i '#{@filter_search}'`.split("\n").reverse
    end

    @page = params[:page].nil? ? 1 : params[:page]
    
    respond_to do |format|
      format.html
      format.js
    end
  end
  
  def search  
  end
  
  private
  
  def sort_column
    return :created_at unless params.has_key?(:sort)
    return params[:sort].to_sym if Log::SORT.has_key?(params[:sort].to_sym)
    :created_at
  end
  
  def sort_direction
    %w[asc desc].include?(params[:direction].to_s) ? params[:direction].to_sym : :desc
  end
  
end