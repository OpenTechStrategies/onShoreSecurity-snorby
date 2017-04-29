class DbversionSource

  include DataMapper::Resource

  property :id, Serial

  belongs_to :ruleDbversion, :child_key => [ :dbversion_id ]
  belongs_to :ruleSource, :child_key => [ :source_id ]


end
