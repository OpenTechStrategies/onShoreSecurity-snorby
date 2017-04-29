class ReputationsController < ApplicationController

  before_filter :find_sensor, :only => [:index, :apply, :order_auto]

  def index
    if @sensor.nil? 
      redirect_to sensors_path  
    else
      @fn_sensor = @sensor.bwlist_reputations_ipnets
      @fc_sensor = @sensor.bwlist_reputations_countries
      @shapes_countries = @fc_sensor.map{|x| {:color => x.action.nil? ? "gray" : x.action.color, :name => x.country.name, :path => x.country.path}}
      #@shapes_countries.concat(Country.all(:id.not => @fc_sensor.map{|x| x.country_id}).map {|x| { :color => '#eaeaea', :name => x.name, :path => x.path} })
     
      @reputation = Reputation.get(params[:reputation_id]) if params[:reputation_id]

      @shapes_countries_drop    = @fc_sensor.select { |x| x.action.id==ReputationAction::ACTION_DROP}.map{|x| {:color => x.action.nil? ? "gray" : x.action.color, :name => x.country.name, :path => x.country.path}}
      @shapes_countries_bypass  = @fc_sensor.select { |x| x.action.id==ReputationAction::ACTION_BYPASS}.map{|x| {:color => x.action.nil? ? "gray" : x.action.color, :name => x.country.name, :path => x.country.path}}
      @shapes_countries_analize = @fc_sensor.select { |x| x.action.id==ReputationAction::ACTION_ANALIZE}.map{|x| {:color => x.action.nil? ? "gray" : x.action.color, :name => x.country.name, :path => x.country.path}}
      @shapes_countries_none    = Country.all(:id.not => @fc_sensor.map{|x| x.country_id}).map {|x| { :color => '#eaeaea', :name => x.name, :path => x.path} }
    end
  end

  def apply 
    if can?(:manage, @sensor)
      unless @sensor.nil? 
        @sensor.save_reputations_chef
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
    @reputation            = Reputation.new
    @sensor                = Sensor.get(params[:sensor_sid])

    if can?(:manage, @sensor)
      @reputation.sensor_sid = params[:sensor_sid]
      @reputation.type_id    = params[:type_id]
      @countries_list        = Country.all(:order => :name).collect{|a| [a.name.downcase.capitalize, a.code_name]}
      @actions_list          = ReputationAction.all.collect{|a| [a.name, a.id]}
      render :layout => false
    else
      redirect_to sensors_path
    end
  end

  # GET /reputations/1/edit
  def edit
    @reputation     = Reputation.get(params[:id])
    @sensor         = @reputation.sensor

    if can?(:manage, @sensor)
      @countries_list = Country.all(:order => :name).collect{|a| [a.name.downcase.capitalize, a.code_name]}
      @actions_list   = ReputationAction.all.collect{|a| [a.name, a.id]}
      @notes          = @reputation.notes
      render :layout => false
    else
      redirect_to sensors_path 
    end
  end

  def create
    @reputation         = Reputation.new(:value => params[:reputation][:value])
    @reputation.action  = ReputationAction.get(params[:reputation][:action_id])
    @reputation.type    = ReputationType.get(params[:reputation][:type_id]) 
    @reputation.country = Country.first(:code_name => params[:reputation][:country_id]) 
    @sensor             = Sensor.get(params[:reputation][:sensor_sid])

    if can?(:manage, @sensor)
      @reputation.sensor  = @sensor 
      respond_to do |format|
        if @reputation.save!
          format.html { redirect_to reputations_path(:sensor_sid => @reputation.sensor_sid), notice: 'Reputation was successfully created.' }
          format.json { render json: @reputations, status: :created, location: @reputations }
        else
          format.html { render action: "new" }
          format.json { render json: @reputation.errors, status: :unprocessable_entity }
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
        Reputation.get(auto_id).update(:position => (position + 1)) if Reputation.get(auto_id).sensor.equal?@sensor
      end
    end
  end

  def update
    @reputation         = Reputation.get(params[:id])
    @reputation.action  = ReputationAction.get(params[:reputation][:action_id])
    @reputation.type    = ReputationType.get(params[:reputation][:type_id]) 
    @reputation.country = Country.first(:code_name => params[:reputation][:country_id]) 
    @reputation.value   = params[:reputation][:value]
    @sensor             = Sensor.get(params[:reputation][:sensor_sid])

    if can?(:manage, @sensor)
      @reputation.sensor  = @sensor 

      respond_to do |format|
        if (can?(:manage, @sensor) or current_user.admin)
          if @reputation.save!
            format.html { redirect_to reputations_path(:sensor_sid => @reputation.sensor_sid), notice: 'Reputation was successfully updated.' }
            format.json { head :ok }
          else
            format.html { render action: "edit" }
            format.json { render json: @reputation.errors, status: :unprocessable_entity }
          end
        else
          format.html { redirect_to reputations_path(:sensor_sid => @sensor.sid) }
        end
      end
    else
      redirect_to sensors_path
    end
  end

  def destroy
    @reputation   = Reputation.get(params[:id])
    @sensor       = Sensor.get(@reputation.sensor_sid)
    @sensor_redir = Sensor.get(params[:sensor_view_sid]) if params[:sensor_view_sid].present?

    if can?(:manage, @sensor) and current_user.admin
      @reputation.destroy

      if @sensor.nil? and @sensor_redir.nil?
        redirect_to sensors_path
      elsif !@sensor_redir.nil?
        redirect_to reputations_path(:sensor_sid => @sensor_redir.sid)
      else
        redirect_to reputations_path(:sensor_sid => @sensor.sid)
      end
    else
      redirect_to sensors_path
    end
  end

  def new_note
    @reputation = Reputation.get(params[:reputation_id])
  end

  def create_note
    @reputation = Reputation.get(params[:reputation_id])
    @note = @reputation.notes.create({ :user => current_user, :body => params[:body] }) if can?(:manage, @reputation.sensor)
    if @note.save
      Delayed::Job.enqueue(Snorby::Jobs::NoteNotification.new(self.class, @note.id))
    end
  end

  def destroy_note
    @note       = ReputationNote.get(params[:id])
    @reputation = @note.reputation
    @note.destroy if can?(:manage, @reputation.sensor)
  end

  private 

  def find_sensor
    @sensor = Sensor.get(params[:sensor_sid]) unless params[:sensor_sid].nil?
    @sensor = Sensor.first(:hostname => params[:sensor_name]) if @sensor.nil? and !params[:sensor_name].nil?
    @sensor = nil unless ( !@sensor.nil? and (can?(:read, @sensor) or current_user.admin) )
    redirect_to sensors_path unless can?(:read, @sensor)
  end

end
