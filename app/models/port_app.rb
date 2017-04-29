class PortApp
  include DataMapper::Resource

  storage_names[:default] = "port_apps"

  property :id, Serial , :key => true, :index => true
  property :name, String,:index => true
  property :description, Text

end
