class RuleCategory3
  # Category3s for each rule. The category3 represent the rule message group. Most of the rules start with the same three words
  #   Example: 
  #      - alert tcp $EXTERNAL_NET any -> $HOME_NET 21 (msg:"ETPRO FTP ProFTPD FTP  ..."; ... classtype:attempted-admin; sid:2800936; rev:2;)
  #           -> "ETPRO FTP ProFTPD"

  include DataMapper::Resource
  
  property :id, Serial, :key => true, :index => true
  property :name, String, :length => 128, :required => true
  property :description, String, :length => 128

  has n, :rules, :child_key => [ :category3_id ], :constraint => :destroy

end
