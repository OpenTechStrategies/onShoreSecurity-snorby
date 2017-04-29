class RoleUser
  include DataMapper::Resource

  property :id     , Serial, :key => true, :index => true

  property :user_id, Integer, :index => true
  property :role_id, Integer, :index => true

  belongs_to :role
  belongs_to :user
  
  audit do |action|
    
    if User.current_user.present?
    
      log_attributes = {:model_name => self.class, :action => 'update', :model_id => self.role_id, :user => User.current_user}

      case action.to_sym
      when :create
        log_attributes.merge!({:message => "Add user #{User.get(user_id).name} to role #{Role.get(role_id).name.capitalize}"})
        Log.new(log_attributes).save
      when :destroy
        # if the user is not been deleted from role before destroy the role.
        if Role.get(role_id)
          log_attributes.merge!({:message => "Remove user #{User.get(user_id).name} from role #{Role.get(role_id).name.capitalize}"})
          Log.new(log_attributes).save
        end
      end
      
    end

  end

end
