class RoleSensor
  include DataMapper::Resource

  property  :id       , Serial, :key => true, :index => true

  property :sensor_sid, Integer, :index => true
  property :role_id   , Integer, :index => true

  belongs_to :sensor, :parent_key => [ :sid ], :child_key => [ :sensor_sid ]
  belongs_to :role
  
  audit do |action|
    
    if User.current_user.present?
    
      log_attributes = {:model_name => self.class, :action => 'update', :model_id => self.role_id, :user => User.current_user}

      case action.to_sym
      when :create
        log_attributes.merge!({:message => "Add sensor #{Sensor.get(sensor_sid).name.capitalize} to role #{Role.get(role_id).name.capitalize}"})
        Log.new(log_attributes).save
      when :destroy
        # if the sensor is not been deleted from role before destroy the role.
        if Role.get(role_id)
          log_attributes.merge!({:message => "Remove sensor #{Sensor.get(sensor_sid).name.capitalize} from role #{Role.get(role_id).name.capitalize}"})
          Log.new(log_attributes).save
        end
      end
      
    end

  end

end