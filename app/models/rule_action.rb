class RuleAction
  # Actions for each rule

  include DataMapper::Resource
  
  property :id, Serial, :key => true, :index => true
  property :name, String, :length => 64, :required => true
  property :description, String, :length => 128

  has n, :rules, :model => 'SensorRule', :child_key => [ :action_id ], :constraint => :destroy

  def inherited?
    self.id == 7
  end

end
