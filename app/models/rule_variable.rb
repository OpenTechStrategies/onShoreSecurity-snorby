class RuleVariable
  include DataMapper::Resource

  IPVAR=0
  PORTVAR=1

  property :id, Serial, :key => true, :index => true
  property :name, String, :length => 64, :required => true
  property :type, Integer, :default => RuleVariable::IPVAR
  property :description, String, :length => 128

  def self.ipvars
    RuleVariable.all(:type=>RuleVariable::IPVAR)
  end

  def self.portvars
    RuleVariable.all(:type=>RuleVariable::PORTVAR)
  end
end
