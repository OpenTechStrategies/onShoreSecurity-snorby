require 'snorby/model/counter'

class Classification

  include DataMapper::Resource
  include Snorby::Model::Counter

  property :id, Serial, :index => true

  property :name, String

  property :description, Text

  property :hotkey, Integer, :index => true

  property :locked, Boolean, :default => false, :index => true

  property :events_count, Integer, :index => true, :default => 0

  has n, :events, :constraint => :destroy

  has n, :auto_classifications, :constraint => :destroy

  validates_uniqueness_of :hotkey
  
  validates_presence_of :name
  
  validates_presence_of :description

  
  audit :name, :description do |action|
    
    if User.current_user.present?
    
      log_attributes = {:model_name => self.class, :action => action, :model_id => self.id, :user => User.current_user}

      case action.to_sym
      when :create
        log_attributes.merge!({:message => "Created #{self.class} '#{self.name}'"})
      when :update
        log_attributes.merge!({:message => changes.collect {|prop, values|
                                                            "Changed #{prop.name} from '#{values[0]}' to '#{values[1]}'"
                                                          }.join(", ")
                              })
      when :destroy
        log_attributes.merge!({:message => "Destroyed #{self.class} '#{self.name}'"})
      end

      Log.new(log_attributes).save

    end

  end
  
  
  def shortcut
    "f#{hotkey}"
  end

  #
  #  
  # 
  def event_percentage
    begin
      ((self.events_count.to_f / Event.count.to_f) * 100).round(2)
    rescue FloatDomainError
      0
    end
  end
  
  
  def self.to_graph
    graph = []
    all.each do |classification|
      graph << {
        :name => classification.name,
        :data => classification.events_count
      }
    end
    graph
  end
  
  def self.to_pie
    graph = []
    all.each do |classification|
      graph << [classification.name, classification.events_count] unless classification.events_count.zero?
    end
    graph
  end

  def self.false_positive
    Classification.first(:name=>"False Positive")
  end

end
