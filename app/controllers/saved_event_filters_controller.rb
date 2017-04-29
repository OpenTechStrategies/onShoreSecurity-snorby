class SavedEventFiltersController < ApplicationController
  
  def index
    @filters = (SavedEventFilter.all(:user_id => @current_user.id) | SavedEventFilter.all(:public => true)).page(params[:page].to_i, :per_page => @current_user.per_page_count, :order => [:created_at])
  end
  
  def new
    @filter = SavedEventFilter.new
    render :layout => false
  end
  
  def create

    if params[:filter]

      if params[:filter].is_a?(String)
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

        @filter = SavedEventFilter.new(params[:filter])

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
    @filter = SavedEventFilter.get(params[:id].to_i)

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
    @filter = SavedEventFilter.get(params[:id].to_i)

    if @filter 
      redirect_to saved_event_filters_path unless @current_user.id == @filter.user.id
    else
      redirect_to saved_event_filters_path
    end
  end
  
  def edit
    @filter = SavedEventFilter.get(params[:id])
  end
  
  def update
    @filter = SavedEventFilter.get(params[:id])
    
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
    @filter = SavedEventFilter.get(params[:id])

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
    @filter = SavedEventFilter.get(params[:id])

    respond_to do |format|
      if @filter && @current_user.id == @filter.user.id
        if @filter.destroy
          format.html { redirect_to saved_event_filters_path, :flash => { :success => "Filter `#{@filter.title}` removed successfully." } }
        else
          format.html { redirect_to saved_event_filters_path, :flash => { :error => "Failed to remove filter `#{@filter.title}` successfully" } }
        end
      else
        format.html { redirect_to saved_event_filters_path }
      end
    end
  end

end