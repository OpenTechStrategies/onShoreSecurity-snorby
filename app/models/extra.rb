class Extra

  include DataMapper::Resource

  storage_names[:default] = "extra"

  belongs_to :sensor, :parent_key => [ :sid ], :child_key => [ :sid ], :required => true

  belongs_to :event, :parent_key => [ :sid, :cid ], :child_key => [ :sid, :cid ], :required => true

  property :id, Integer, :key => true, :index => true

  property :sid, Integer, :key => true, :index => true
  
  property :cid, Integer, :key => true, :index => true
  
  property :type, Integer, :lazy => true
  
  property :datatype, Integer, :lazy => true
  
  property :len, Integer, :lazy => true
  
  property :data, Text, :lazy => true

end
