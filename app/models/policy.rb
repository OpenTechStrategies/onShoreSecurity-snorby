class Policy
  include DataMapper::Resource
  
  property :id, Serial, :key => true, :index => true
  property :name, String, :length => 64, :required => true, :unique => true
  property :description, String, :length => 256

  has n, :rule_policies, :model => 'RulePolicy', :child_key => [ :policy_id ], :parent_key => [ :id ], :constraint => :destroy
  has n, :rules, :through => :rule_policies  
  #has n, :actions, :through => :rule_policies
end
