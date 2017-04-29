class RuleComment
  # Comments for each sensor rule.
  #   When an user add a rule to one sensor he/she can add some comments to this action

  include DataMapper::Resource
  
  property :id, Serial, :key => true
  property :body, Text
  property :timestamp, DateTime, :required => true

  belongs_to :sensorRule, :parent_key => [ :id ], :child_key => [ :sensorRule_id ]
  belongs_to :user      , :parent_key => [ :id ], :child_key => [ :user_id ]	

end
