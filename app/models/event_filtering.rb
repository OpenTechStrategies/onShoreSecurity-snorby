require 'snorby/model'

class EventFiltering

	include Snorby::Model
  include DataMapper::Resource

 	property :id, Serial, :index => true
 	property :sid, Integer
  property :sig_sid, Integer
  property :sig_gid, Integer
 	property :filtering_type, String
  property :count, Integer, :default => 1
  property :seconds, Integer, :default => 1
  property :tracked_type, String
  property :tracked_ip, Text
  property :position, Integer, :default => lambda { |r, p| (EventFiltering.max(:position) || 0) + 1 }
  
  belongs_to :sensor, :parent_key => :sid, :child_key => :sid

  has n, :notes, :model => 'EventFilteringNote', :child_key => [ :discriminator_id ], :constraint => :destroy

  validates_uniqueness_of :tracked_ip, :scope => [:sid, :sig_sid, :sig_gid, :filtering_type, :tracked_type, :count, :seconds]

 	audit :sid, :sig_sid, :sig_gid, :filtering_type, :count, :seconds, :tracked_type, :tracked_ip do |action|    
    if User.current_user.present?    
      log_attributes = {:model_name => self.class, :action => action, :model_id => self.id, :user => User.current_user}
      case action.to_sym
      when :create
        log_attributes.merge!({:message => "Created #{self.class} #{self.description}  (id=#{self.id})"})
      when :update
        log_attributes.merge!({:message => changes.collect  { |prop, values| 
          case prop.name.to_sym
          when :sid
            "Changed sensor from '#{get_name(Sensor.get(values[0]))}' to '#{get_name(Sensor.get(values[1]))}' for the #{self.description}"
          else
            "Changed #{prop.name} from '#{values[0]}' to '#{values[1]}' for the sensor '#{self.sensor.name}'"
          end
        }.join(", ")})
      when :destroy
        log_attributes.merge!({:message => "Destroyed #{self.class} with id='#{self.id}' for the sensor '#{self.sensor.name}'"})
      end
      Log.new(log_attributes).save
    end
  end

  alias_method :id_email, :id

  def log_name
    self.sensor.name
  end

  def description
    self.relevant_fields.to_s
  end

  def threshold?
    self.filtering_type=="threshold"
  end

  def limit?
    self.filtering_type=="limit"
  end

  def both?
    self.filtering_type=="both"
  end

  def suppress?
    self.filtering_type=="suppress"
  end

  def signature_name
    signature_name = Rule.first(:rule_id => sig_sid, :gid => sig_gid, :dbversion_id => sensor.dbversion_id).msg
    return signature_name unless signature_name.nil?
    Rule.first(:rule_id => sig_sid, :gid => sig_gid, :order => [:rev.desc]).msg
  end

  def rule 
    rule = Rule.last(:rule_id => self.sig_sid, :gid => self.sig_gid, :dbversion_id => sensor.dbversion_id)
    rule = Rule.last(:rule_id => self.sig_sid, :gid => self.sig_gid) if rule.nil?
    rule
  end

  def relevant_fields
    return {
      :sig_gid => self.sig_gid,
      :sig_sid => self.sig_sid,
      :filtering_type => self.filtering_type,
      :count => self.count,
      :seconds => self.seconds,
      :tracked_type => self.tracked_type,
      :tracked_ip => self.tracked_ip
    }
  end

  protected

  def get_name(ob)
    ob.nil? ? "none" : ob.name
  end

end