class SnortStatName
  
  include DataMapper::Resource

  
  property :id, Serial, :key => true, :index => true
  
  property :name, String

  property :text_name, String
  
  property :measure_unit, String

  property :enable, Boolean, :default => true

  has n, :snortStats


  def text_name
  	return name if super.nil?
  	super
  end

end