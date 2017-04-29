class RolesController < ApplicationController

  before_filter :require_administrative_privileges
  before_filter :find_role, :except => [ :index ]

  def index
    @roles = Role.all(:order => [:name.asc])
  end

  def new
    render :layout => false
  end

  def create
    @role = Role.create(params[:role])
    flash[:notice] = "Role successfully created."
    redirect_to role_path(@role)
  end

  def edit
  end

  def update
    if @role.update(params[:role])
      redirect_to(role_path, :notice => 'Role was successfully updated.')
    else
      redirect_to(role_path, :notice => 'Was an error updating the role.')
    end

  end

  def destroy
    if params[:sensor_sid].present?
      @role.roleSensors.all(:sensor_sid => params[:sensor_sid]).destroy
      redirect_to role_path(@role)
    elsif params[:user_id].present?
      @role.roleUsers.all(:user_id => params[:user_id]).destroy
      redirect_to role_path(@role)
    else
      @role.destroy!
      redirect_to roles_path
    end
  end

  def delete_user
    if params[:user_id].present?
      @user = User.get(params[:user_id])
      @role.roleUsers.all(:user_id => params[:user_id].to_i).destroy
      respond_to :js      
    else
      redirect_to role_path(@role)
    end
  end

  def delete_sensor
    if params[:sensor_sid].present?
      @sensor = Sensor.get(params[:sensor_sid])
      @role.roleSensors.all(:sensor_sid => params[:sensor_sid]).destroy
      respond_to :js
    else
      redirect_to role_path(@role)
    end
  end

  def add_users
    @role = Role.get(params[:role_id])
    @users = User.all - @role.users
    render :layout => false
  end

  def add_user
    @user = User.get(params[:user_id])
    @role.users << @user unless @user.nil?
    @role.save
    respond_to :js
  end

  def add_sensors
    @role = Role.get(params[:role_id])
    hierarchy = Sensor.root.hierarchy(10)
    if hierarchy.nil?
      @sensors = []
    else
      @sensors ||= hierarchy.flatten.compact unless hierarchy.nil?
    end
    
    @role.sensors.each do |s|
      @sensors.delete(s)
    end
    render :layout => false
  end

  def add_sensor
    @sensor = Sensor.get(params[:sensor_sid])
    @role.sensor_ids= @role.sensor_ids << @sensor.sid
    @role.save
    respond_to :js
  end

  private

    def find_role
      params[:id].nil? ? @role = Role.new : @role = Role.get(params[:id])
    end

end
