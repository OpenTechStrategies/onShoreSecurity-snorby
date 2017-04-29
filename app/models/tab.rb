class Tab
  include DataMapper::Resource

  property :id, Serial, :key => true, :index => true
  property :column, String
  property :position, Integer, :default => lambda { |r, p| (Tab.max(:position) || 0) + 1 }

  property :type, Discriminator

  belongs_to :user

end

class DashboardTab < Tab; end
class SnmpTab < Tab; end
