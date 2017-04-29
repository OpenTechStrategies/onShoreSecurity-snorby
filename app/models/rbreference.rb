class Rbreference
  include DataMapper::Resource
  
  property :id, Serial, :key => true, :index => true
  property :name, String, :length => 64, :required => true, :unique => true
  property :description, String, :length => 128
  property :prefix, String, :length => 128

  has n, :rule_references, :model => 'RuleRbreference', :child_key => [ :reference_id ], :parent_key => [ :id ], :constraint => :destroy
  has n, :rules, :through => :rule_references

  def self.bugtraq
    Rbreference.first(:name => "bugtraq")
  end

  def self.nessus
    Rbreference.first(:name => "nessus")
  end

  def self.cve
    Rbreference.first(:name => "cve")
  end
  
end
