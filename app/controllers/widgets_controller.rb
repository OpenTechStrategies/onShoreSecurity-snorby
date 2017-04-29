class WidgetsController < ApplicationController

  before_filter :get_widget, :except => [:index, :new, :create]

  def index
    session[:filter]={} if session[:filter].nil?
    @col_widgets = User.current_user.widgets.all(:order => [:column_position, :position]).group_by { |x| x.column_position } 
    @col_widgets[0] = [] if @col_widgets[0].nil?
    @col_widgets[1] = [] if @col_widgets[1].nil?

    #@filters = (SavedEventFilter.all(:user_id => @current_user.id, :limit => 5) | SavedEventFilter.all(:public => true, :limit => 5, :user_id.not => @current_user.id)).all(:order => :title)

    respond_to do |format|
      format.js
      format.html # index.html.erb
      format.xml  { render :xml => @col_widgets }
    end
  end

  def show
    respond_to do |format|
      format.html 
      format.xml  { render :xml => @widget }
    end
  end

  def new
    @widget      = Widget.new
    @widget.user = User.current_user
    render :layout => false
  end

  def edit
    if @widget.nil?
      render :js => ""
    else
      render :layout => false
    end
  end

  def create
    @widget = Widget.new(params[:widget])
    @widget.user = User.current_user

    if @widget.save
      @widget.change_position_best
      redirect_to(widgets_url, :notice => 'Widget successfully created.')
    else
      redirect_to(widgets_url, :notice => 'Widget not created!!')
    end
  end

  def update
    if @widget.update(params["widget"])
      redirect_to(widgets_url, :notice => 'Widget successfully updated.')
    else
      redirect_to(widgets_url, :notice => 'Widget not updated!!')
    end
  end

  def show_table
    @column     = @widget.column
    @range      = @widget.range
    @metric     = @widget.metric
    @graph_type = @widget.graph_type
    @now        = Time.zone.now
    @lookups  ||= Setting.lookups? ? Lookup.all : []

    set_defaults

    set_table_metric(@column.to_sym)

    @total_events = @table_metrics.map{|x| x[1]}.sum

    respond_to do |format|
      format.js
    end
  end

  def remove
    @widget.destroy
    render :js => ""
  end
  
  def change_visibility
    @minimized  = params[:minimized].blank? ? false : params[:minimized] == "1"
    @widget.update(:minimized => @minimized) unless @widget.nil?

    respond_to do |format|
      format.js
    end
  end

  def change_position
    @column_position  = params[:column_position].blank? ? 0 : params[:column_position].to_i
    @position         = params[:position].blank? ? 0 : params[:position].to_i

    @widget.change_position(@column_position, @position) unless @widget.nil?

    respond_to do |format|
      format.js
    end
  end
  
  def add_widget
    common_defaults
  end

  def reload
    @table_loaded = (params[:table_loaded]=="true" || params[:table_loaded]=="1")

    common_defaults
    
    if @table_loaded
      set_table_metric(@column.to_sym)
      @total_events = @table_metrics.map{|x| x[1]}.sum
    else
      @metric_table = {}
    end
  end

  private 

  def get_widget
    @widget = Widget.get(params[:id].to_i)
    @widget = nil unless User.current_user.widgets.include?(@widget) 
  end

  def common_defaults(show_chart=true)
    unless @widget.nil? 
      @column     = @widget.column
      @range      = @widget.range
      @metric     = @widget.metric
      @graph_type = @widget.graph_type

      @now        = Time.zone.now
      @lookups  ||= Setting.lookups? ? Lookup.all : []
      @axis   = Cache.count_hash(@range.to_sym).keys

      set_defaults
      set_metric(@column.to_sym)
    end
  end

end
