require 'snorby/model'

class Severity
  
  include Snorby::Model
  include DataMapper::Validate
  include DataMapper::Resource

  has n, :signatures, :child_key => :sig_priority, :parent_key => :sig_id

  property :id, Serial, :index => true, :key => true
  
  property :sig_id, Integer, :index => true, :unique => true
  
  property :events_count, Integer, :index => true, :default => 0
  
  # Set the name of the severity
  property :name, String

  # Set the severity text color
  property :text_color, String, :default => '#ffffff', :index => true
  
  # Set the severity background color
  property :bg_color, String, :default => '#dddddd', :index => true

  validates_presence_of :sig_id, :name, :text_color
  validates_uniqueness_of :sig_id
  validates_format_of :text_color, :with => /^#?([a-f]|[A-F]|[0-9]){3}(([a-f]|[A-F]|[0-9]){3})?$/, :message => "is invalid"
  validates_format_of :bg_color, :with => /^#?([a-f]|[A-F]|[0-9]){3}(([a-f]|[A-F]|[0-9]){3})?$/, :message => "is invalid"

  has n, :classtypes, :model => 'RuleCategory2', :child_key => :severity_id, :parent_key => :sig_id
  
  audit :sig_id, :name, :text_color, :bg_color do |action|
    
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
  
  
  def locked?
    return true if [1,2,3].include?(id)
    false
  end

end
