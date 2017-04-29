class RuleCategory1
  # Category1s for each rule. The category1 represent the filename where the rule has been found 

  include DataMapper::Resource
  
  property :id, Serial, :key => true, :index => true
  property :name, String, :length => 128, :required => true
  property :description, String, :length => 128

  has n, :rules, :child_key => [ :category1_id ], :constraint => :destroy
end
