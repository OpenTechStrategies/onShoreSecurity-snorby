class ReputationAction
  include DataMapper::Resource
  # Actions for each reputation
  #ACTIONS = [["analize", 1], ["bypass", 2], ["drop", 3]]
  ACTION_ANALIZE= 1
  ACTION_BYPASS = 2
  ACTION_DROP   = 3


  property :id, Serial, :key => true, :index => true
  property :name, String, :length => 64, :required => true, :default => 'bypass' # Analize / Bypass / Drop
  property :color, String, :default => '#ffffff'
  
  has n, :reputations, :model => 'Reputation', :child_key => [ :action_id ], :constraint => :destroy

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

  def self.analize_action
  	return self.get(ACTION_ANALIZE)
  end

  def self.bypass_action
  	return self.get(ACTION_BYPASS)
  end

  def self.drop_action
  	return self.get(ACTION_DROP)
  end
  
end
