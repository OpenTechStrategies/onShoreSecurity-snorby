class FlowbitState
  include DataMapper::Resource
  
  property :id, Serial, :key => true, :index => true
  property :name, String, :length => 128, :required => true, :unique => true
  property :description, String, :length => 256

  has n, :rule_flowbits, :model => 'RuleFlowbit', :child_key => [ :state_id ], :parent_key => [ :id ], :constraint => :destroy
  has n, :rules, :through => :rule_flowbits


end
