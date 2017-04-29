class Role
  include DataMapper::Resource

  PERMISSIONS = [["read", "read"], ["manage", "manage"], ["none", "none"]]

  property  :id         , Serial, :key => true, :index => true
  property  :name       , String, :required => true, :unique => true
  property  :permission , String, :default => 'read'
  
  
  audit :name, :permission do |action|
    
    if User.current_user.present?
    
      log_attributes = {:model_name => self.class, :action => action, :model_id => self.id, :user => User.current_user}

      case action.to_sym
      when :create
        log_attributes.merge!({:message => "Created #{self.class} '#{self.name}'"})
      when :update
        log_attributes.merge!({:message => changes.collect {|prop, values|
                                                            "Changed #{prop.name} from '#{values[0]}' to '#{values[1]}'"
                                                          }.join(", ")
                              })
      when :destroy
        log_attributes.merge!({:message => "Destroyed #{self.class} '#{self.name}'"})
      end

      Log.new(log_attributes).save
      
    end

  end
  

  has n, :users, :through => :roleUser
  has n, :sensors, :through => :roleSensor

  has n, :roleSensors
  has n, :roleUsers  

  # constraint => :destroy fails
  before :destroy! do
    self.roleSensors.destroy
    self.roleUsers.destroy
  end

  def sensor_ids
    self.sensors.map{|s| s.sid}
  end

  def sensor_ids=(sensors)
    self.sensors = []
    self.sensors = Sensor.all(:sid => sensors)
    self.save
  end

  def user_ids
    self.users.map{|u| u.id}
  end

  def user_ids=(users)
    self.users = []
    self.users = User.all(:id => users)
    self.save
  end

end
