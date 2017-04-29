class RuleCategory4
  include DataMapper::Resource
  
  property :id, Serial, :key => true, :index => true
  property :name, String, :length => 128, :required => true
  property :description, String, :length => 128

  has n, :rules, :child_key => [ :category4_id ], :constraint => :destroy

  def self.preprocessors
    RuleCategory4.first(:name=>"preprocessors")
  end
end
