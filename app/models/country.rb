class Country
  include DataMapper::Resource
  
  property :id, Serial, :key => true, :index => true
  property :code_name, String, :length => 64, :required => true
  property :name, String, :length => 64, :required => true
  property :contour, Text, :required => true, :default => ""
  property :profile_map, String, :required => false, :default => ""

  has n, :reputations, :model => 'Reputation', :child_key => [ :country_id ], :constraint => :destroy

  def path
    self.contour.split.map{|x| Integer(x)  rescue x}
  end

end
