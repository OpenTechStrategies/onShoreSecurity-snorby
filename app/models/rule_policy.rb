class RulePolicy
  include DataMapper::Resource
  
  property :id, Serial, :key => true, :index => true
  property :action_id, Integer, :required => true

  belongs_to :rule
  belongs_to :policy
  belongs_to :action, :model => 'RuleAction', :child_key => [ :action_id ]

end
