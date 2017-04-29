class RuleRbreference
  include DataMapper::Resource
  
  property :id, Serial, :key => true, :index => true
  property :url, String, :length => 512, :required => true

  belongs_to :rule
  belongs_to :reference, :model => 'Rbreference'

end
