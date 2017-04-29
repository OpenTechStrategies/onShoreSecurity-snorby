class Reputation
  include DataMapper::Resource
  # TYPE [1 IP-Network, 2 Country]
  # ACTION [1 Analize, 2 Bypass, 3 Drop]
  property :id, Serial, :key => true, :index => true
  property :value, String 
  property :position, Integer, :default => lambda { |r, p| (Reputation.max(:position) || 0) + 1 }
      
  belongs_to :sensor   	, :model => 'Sensor'           , :child_key => [ :sensor_sid ], :required => false
  belongs_to :action    , :model => 'ReputationAction' , :child_key => [ :action_id ] , :required => false
  belongs_to :type      , :model => 'ReputationType'   , :child_key => [ :type_id ]   , :required => false
  belongs_to :country   , :model => 'Country'     	   , :child_key => [ :country_id ], :required => false

  has n, :notes, :model => 'ReputationNote', :child_key => [ :discriminator_id ], :constraint => :destroy

  audit :value do |action|    
    if User.current_user.present?    
      log_attributes = {:model_name => self.class, :action => action, :model_id => self.id, :user => User.current_user}
      case action.to_sym
      when :create
        log_attributes.merge!({:message => "Created #{self.class} with id='#{self.id}'"})
      when :update
        log_attributes.merge!({:message => changes.collect {|prop, values| "Changed #{prop.name} from '#{values[0]}' to '#{values[1]}'"}.join(", ")                              })
      when :destroy
        log_attributes.merge!({:message => "Destroyed #{self.class} with id='#{self.id}'"})
      end
      Log.new(log_attributes).save
    end
  end

  alias_method :id_email, :id

  def real_value
    result= if self.type_id == ReputationType::TYPE_NETWORK
      value
    else
      self.country.nil? ? self.value : self.country.name
    end
    result
  end

  def relevant_fields
    return {
      :action => self.action.name,
      :value => (self.type.id == ReputationType::TYPE_NETWORK ? value : country.code_name)
    }
  end
end