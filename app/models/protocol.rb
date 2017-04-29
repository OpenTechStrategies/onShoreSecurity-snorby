class Protocol
  include DataMapper::Resource

  storage_names[:default] = "protocols"

  property :id         , Serial , :key => true, :index => true
  property :name       , String
  property :description, Text


end