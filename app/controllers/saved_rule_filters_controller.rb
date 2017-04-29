class SavedRuleFiltersController < ApplicationController
  
  before_filter :get_sensor, :except => [:create, :title, :update]

  def index
    @filters = (SavedRuleFilter.all(:user_id => @current_user.id) | SavedRuleFilter.all(:public => true)).page(params[:page].to_i, :per_page => @current_user.per_page_count, :order => [:created_at])
  end
  
  def new
    @filter = SavedRuleFilter.new
    render :layout => false
  end
  
  def create

    if params[:filter]

      if params[:rfilter].is_a?(String)
        params[:filter] = JSON.parse(params[:filter])
      end

      #Chech has any param
      has_something = false
      unless params[:filter][:filter][:items].nil?
        params[:filter][:filter][:items].each do |k, filter_item|
          if filter_item[:enabled] and filter_item[:enabled]!=nil
            has_something=true
          end
        end
      end

      if has_something
        params[:filter][:user_id] = @current_user.id

        @filter = SavedRuleFilter.new(params[:filter])

        if @filter.save
          render :json => @filter
        else
          render :json => { :error => @filter.errors }
        end
      else
        render :json => { :error => "Empty filters are not allowed" }
      end
    end
  end
  
  def show
    @filter = SavedRuleFilter.get(params[:id].to_i)

    if @filter 
      if @current_user.id == @filter.user.id or @filter.public
        render :json => @filter
      else
        render :json => {}
      end
    else
      render :json => {}
    end
  end

  def view
    @filter = SavedRuleFilter.get(params[:id].to_i)

    if @filter 
      redirect_to saved_rule_filters_path unless @current_user.id == @filter.user.id
    else
      redirect_to saved_rule_filters_path
    end
  end
  
  def edit
    @filter = SavedRuleFilter.get(params[:id])
  end
  
  def update

    @filter = SavedRuleFilter.get(params[:id])
    
    if @filter && @current_user.id == @filter.user.id
      if params.has_key?(:filter)

        if params[:filter].is_a?(String)
          params[:filter] = JSON.parse(params[:filter])
        end

        @filter.filter = params[:filter]
      end

      if params.has_key?(:public)
        @filter.public = params[:public]
      end

      if @filter.save
        render :json => @filter
      else
        render :json => { :error => @filter.errors }
      end
    else
      render :json => { }
    end
  end

  def title
    @filter = SavedRuleFilter.get(params[:id])

    if @filter && @current_user.id == @filter.user.id
      @filter.title = params[:title] if params.has_key?(:title)

      if params.has_key?(:filter)

        if params[:filter].is_a?(String)
          params[:filter] = JSON.parse(params[:filter])
        end

        @filter.filter = params[:filter]
      end

      if @filter.save
        render :text => @filter.title
      else
        render :json => @filter.errors
      end
    end

  end

  def destroy
    @filter = SavedRuleFilter.get(params[:id])

    respond_to do |format|
      if @filter && @current_user.id == @filter.user.id
        if @filter.destroy
          format.html { redirect_to sensor_saved_rule_filters_path(:sensor_id => @sensor.sid), :flash => { :success => "Filter `#{@filter.title}` removed successfully." } }
        else
          format.html { redirect_to sensor_saved_rule_filters_path(:sensor_id => @sensor.sid), :flash => { :error => "Failed to remove filter `#{@filter.title}` successfully" } }
        end
      else
        format.html { redirect_to sensor_saved_rule_filters_path(:sensor_id => @sensor.sid) }
      end
    end
  end

  private

  def get_sensor
    @sensor = Sensor.get(params[:sensor_id]) unless params[:sensor_id].nil?
  end

end