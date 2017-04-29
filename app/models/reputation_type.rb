class ReputationType
  include DataMapper::Resource
  # Type for each reputation
  # TYPES = ip_network/country
  TYPE_NETWORK=1
  TYPE_COUNTRY=2
  
  property :id, Serial, :key => true, :index => true
  property :name, String, :length => 64, :required => true # IP-Network / Country  
  has n, :reputations, :model => 'Reputation', :child_key => [ :type_id ], :constraint => :destroy

  audit :name do |action|    
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
  
  def self.network_type
  	return self.get(TYPE_NETWORK)
  end

  def self.country_type
  	return self.get(TYPE_COUNTRY)
  end

end
