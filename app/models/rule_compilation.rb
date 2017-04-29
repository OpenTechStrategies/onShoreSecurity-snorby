class RuleCompilation
  # Changes applied to one sensor will not be applied to the snort directly until this sensor is compiled
  # Every sensor (domain or not) can be rollback to any compilation time.
  # A compilation of a domain will involve a compilation of each of the sensors contained in the domain

  include DataMapper::Resource
  
  property :id, Serial, :key => true, :index => true
  property :timestamp, DateTime, :index => true, :required => true
  property :name, String

  has n, :sensorRules, :model => 'SensorRule', :child_key => [ :compilation_id ], :constraint => :destroy
  has n, :rules, :through => :sensorRules
  
  belongs_to :user  , :parent_key => [ :id ], :child_key => [ :user_id ]
  belongs_to :sensor, :parent_key => :sid, :child_key => :sid, :required => true

  
  audit :name do |action|
    
    log_attributes = {:model_name => self.class, :action => action, :model_id => self.id }
  
    user = User.get(self.user_id)

    log_attributes.merge!({:user => user}) if user

    case action.to_sym
    when :create
      log_attributes.merge!({:message => "Created compilation '#{self.name}'"})
    
    when :update
      log_attributes.merge!({:message => "Updated compilation '#{self.name}'"})  

    when :destroy
      log_attributes.merge!({:message => "Destroyed compilation '#{self.name}'"})  
    end
  
    Log.new(log_attributes).save

  end
  
  
  def pretty_timestamp
    timestamp.strftime('%b %d, %Y %I:%M %p')
  end


end
