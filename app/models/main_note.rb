class MainNote

  include DataMapper::Resource

  property :id, Serial, :key => true
  property :user_id, Integer, :index => true
  property :body, Text, :lazy => true
  property :type, Discriminator

  timestamps :at
  
  belongs_to :user
  
  validates_presence_of :body

  def html_id
    "note_#{id}"
  end

end