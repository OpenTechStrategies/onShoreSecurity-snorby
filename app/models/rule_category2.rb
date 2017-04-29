class RuleCategory2
  # Category2s for each rule. The category2 represent the class-type include in the rule message 
  #   Example: 
  #      - alert tcp $EXTERNAL_NET any -> $HOME_NET 21 (msg:"ETPRO FTP ..."; ... classtype:attempted-admin; sid:2800594; rev:2;) 
  #           -> "attempted-admin"

  include DataMapper::Resource
  
  property :id, Serial, :key => true, :index => true
  property :name, String, :length => 128, :required => true
  property :description, String, :length => 128
  property :severity_id, Integer, :index => true, :default => 3
  property :dbversion_id, Integer, :index => true, :default => 1

  has n, :rules, :child_key => [ :category2_id ], :constraint => :destroy
  belongs_to :severity, :parent_key => :sig_id, :child_key => :severity_id
  belongs_to :dbversion, :model => 'RuleDbversion', :parent_key => :id, :child_key => :dbversion_id, :required => true

end
