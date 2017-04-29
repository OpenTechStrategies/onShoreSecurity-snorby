class EventFilteringsController < ApplicationController

  before_filter :find_sensor, :only => [:index, :apply, :order_auto]

  def index
    if @sensor.nil? 
      redirect_to sensors_path  
    else
      @suppress_rules  = @sensor.suppress_events_rules
      @limit_rules     = @sensor.limit_events_rules
      @all_rules       = @sensor.all_events_rules
      @event_filtering = EventFiltering.get(params[:event_filtering_id]) if params[:event_filtering_id]
    end
  end

  def apply 
    if can?(:manage, @sensor)
      unless @sensor.nil? 
        @sensor.save_thresholds_chef
        @sensor.wakeup_chef
      end
      respond_to do |format|
        format.js
      end
    else
      redirect_to sensors_path
    end
  end

  def new
    @event_filtering = EventFiltering.new(:sid => params[:sid], :filtering_type => params[:filtering_type])
    @sensor          = Sensor.get(params[:sid])

    if can?(:manage, @sensor)
      @rules = @sensor.rules.collect{|r| [r.msg.truncate(80), r.id]}
      render :layout => false
    else
      redirect_to sensors_path
    end
  end

  def edit
    @event_filtering = EventFiltering.get(params[:id])
    @sensor          = @event_filtering.sensor

    if can?(:manage, @sensor)
      @notes           = @event_filtering.notes
      render :layout => false
    else
      redirect_to sensors_path
    end
  end

  def create
    @rule            = Rule.get(params[:signature])
    @sensor          = Sensor.get(params[:event_filtering][:sid])

    if can?(:manage, @sensor)
      @event_filtering = EventFiltering.new(params[:event_filtering])

      respond_to do |format|
        if @event_filtering.save!
          @event_filtering.update(:sig_sid => @rule.rule_id, :sig_gid => @rule.gid) 
          format.html { redirect_to event_filterings_path(:sid => @event_filtering.sid), notice: '#{@event_filtering.filtering_type} rule was successfully created.' }
          format.json { render json: @event_filtering, status: :created }
        else
          format.html { render action: "new" }
          format.json { render json: @event_filtering.errors, status: :unprocessable_entity }
        end
      end
    else
      redirect_to sensors_path
    end
  end

  def order_auto
    if can?(:manage, @sensor)
      order = params[:positions].split(";")
      order.each_with_index do |auto_id, position|
        EventFiltering.get(auto_id).update(:position => (position + 1)) if EventFiltering.get(auto_id).sensor.equal?@sensor
      end
    end
  end

  def update
    @sensor          = Sensor.get(params[:event_filtering][:sid])

    if can?(:manage, @sensor)
      @event_filtering = EventFiltering.get(params[:id])
      @event_filtering.update(params[:event_filtering])
          
      respond_to do |format|
        if (can?(:manage, @sensor) or current_user.admin)
          if @event_filtering.save!
            format.html { redirect_to event_filterings_path(:sid => @event_filtering.sid), notice: '#{@event_filtering.filtering_type} rule was successfully updated.' }
            format.json { head :ok }
          else
            format.html { render action: "edit" }
            format.json { render json: @event_filtering.errors, status: :unprocessable_entity }
          end
        else
          format.html { redirect_to event_filterings_path(:sid => @sensor.sid) }
        end
      end
    else
      redirect_to sensors_path 
    end
  end

  def destroy
    @event_filtering = EventFiltering.get(params[:id])
    @sensor          = @event_filtering.sensor unless @event_filtering.nil?

    if can?(:manage, @sensor)
      @sensor_redir    = Sensor.get(params[:sensor_view_sid].to_i) if params[:sensor_view_sid].present?

      if !@sensor.nil? and !@event_filtering.nil?
        @event_filtering.destroy
      end

      if @sensor.nil? and @sensor_redir.nil?
        redirect_to sensors_path
      elsif !@sensor_redir.nil?
        redirect_to event_filterings_path(:sid => @sensor_redir.sid)
      else
        redirect_to event_filterings_pathpath(:sid => @sensor.sid)
      end
    else
      redirect_to sensors_path
    end
  end

  def new_note
    @event_filtering = EventFiltering.get(params[:event_filtering_id])
  end

  def create_note
    @event_filtering = EventFiltering.get(params[:event_filtering_id])
    @note = @event_filtering.notes.create({ :user => current_user, :body => params[:body] }) if can?(:manage, @event_filtering.sensor)
    if @note.save
      Delayed::Job.enqueue(Snorby::Jobs::NoteNotification.new(self.class, @note.id))
    end
  end

  def destroy_note
    @note = EventFilteringNote.get(params[:id])
    @event_filtering = @note.event_filtering
    @note.destroy if can?(:manage, @event_filtering.sensor)
  end

  private 

  def find_sensor
    @sensor = Sensor.get(params[:sid]) unless params[:sid].nil?
    @sensor = Sensor.first(:hostname => params[:sensor_name]) if @sensor.nil? and !params[:sensor_name].nil?
    @sensor = nil unless ( !@sensor.nil? and (can?(:read, @sensor) or current_user.admin) )
  end

end