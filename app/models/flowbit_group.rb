class FlowbitGroup
  include DataMapper::Resource
  
  property :id, Serial, :key => true, :index => true
  property :name, String, :length => 64, :required => true, :unique => true
  property :description, String, :length => 128

  has n, :rule_flowbits, :model => 'RuleFlowbit', :child_key => [ :group_id ], :parent_key => [ :id ], :constraint => :destroy
  has n, :rules, :through => :rule_flowbits


end
