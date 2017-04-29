require "digest"

class SavedFilter

  include DataMapper::Resource

  property :id, Serial, :key => true
  
  property :user_id, Integer, :index => true

  property :public, Boolean, :index => true, :default => false

  property :title, String

  property :filter, Object, :lazy => true

  property :checksum, Text

  property :type, Discriminator

  timestamps :at
  
  belongs_to :user

  validates_presence_of :filter, :user_id, :title, :checksum

  validates_uniqueness_of :checksum

  before :valid?, :set_checksum

  before :create do
    set_checksum
  end

  before :update do
    set_checksum
  end

  def set_checksum(context = :default)
    self.checksum = Digest::SHA2.hexdigest("#{self.user_id}#{self.filter}")
  end

end