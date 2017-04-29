class RuleService
  include DataMapper::Resource
  
  property :id, Serial, :key => true, :index => true
  #property :rule_id, Integer, :required => true
  #property :service_id, Integer, :required => true
  
  belongs_to :rule
  belongs_to :service

end
