class RuleNote

  include DataMapper::Resource

  property :id, Serial, :key => true, :index => true
  property :body, Text, :lazy => true
  timestamps :at

  belongs_to :rule, :parent_key => [ :rule_id, :gid ], :child_key => [ :rule_sid, :rule_gid ]
  belongs_to :user, :parent_key => [ :id ]     , :child_key => [ :user_id ]

  validates_presence_of :body

  def html_id
    "note_#{id}"
  end

end
