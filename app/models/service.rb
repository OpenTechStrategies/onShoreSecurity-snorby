class Service
  include DataMapper::Resource
  
  property :id, Serial, :key => true, :index => true
  property :name, String, :length => 64, :required => true, :unique => true
  property :description, String, :length => 128

  has n, :rule_services, :model => 'RuleService', :child_key => [ :service_id ], :parent_key => [ :id ], :constraint => :destroy
  has n, :rules, :through => :rule_services
end
