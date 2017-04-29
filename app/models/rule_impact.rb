class RuleImpact
  include DataMapper::Resource
  
  property :id, Serial, :key => true, :index => true

  belongs_to :rule
  belongs_to :impact
  
end
