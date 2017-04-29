class Impact
  include DataMapper::Resource
  
  property :id, Serial, :key => true, :index => true
  property :name, String, :length => 64, :required => true, :unique => true
  property :description, String, :length => 128

  has n, :rule_impacts, :model => 'RuleImpact', :child_key => [ :impact_id ], :parent_key => [ :id ], :constraint => :destroy
  has n, :rules, :through => :rule_impacts
end
