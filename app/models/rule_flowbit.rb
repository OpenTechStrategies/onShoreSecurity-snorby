class RuleFlowbit
  include DataMapper::Resource
  
  property :id, Serial, :key => true, :index => true
  property :state_id, Integer, :required => false
  property :group_id, Integer, :required => false

  belongs_to :rule
  belongs_to :flowbit
  belongs_to :state, :model => 'FlowbitState', :child_key => [ :state_id ]
  belongs_to :group, :model => 'FlowbitGroup', :child_key => [ :group_id ]

end
