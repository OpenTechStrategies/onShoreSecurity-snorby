require 'snorby/model'

class AutoClassification

	include Snorby::Model
  include DataMapper::Resource

 	property :id, Serial, :index => true
 	property :sid, Integer
 	property :ip_src, String
 	property :ip_dst, String
 	property :sig_sid, Integer
 	property :sig_gid, Integer
  property :position, Integer, :default => lambda { |r, p| (AutoClassification.max(:position) || 0) + 1 }

  belongs_to :classification

 	
 	audit :sid, :ip_src, :ip_dst, :sig_sid, :sig_gid do |action|
    
    if User.current_user.present?
    
      log_attributes = {:model_name => self.class, :action => action, :model_id => self.id, :user => User.current_user}

      case action.to_sym
      when :create
        log_attributes.merge!({:message => "Created #{self.class} with id='#{self.id}'"})
      when :update
        log_attributes.merge!({:message => changes.collect {|prop, values|
                                                            "Changed #{prop.name} from '#{values[0]}' to '#{values[1]}'"
                                                          }.join(", ")
                              })
      when :destroy
        log_attributes.merge!({:message => "Destroyed #{self.class} with id='#{self.id}'"})
      end

      Log.new(log_attributes).save

    end

  end

  def sensor
    return Sensor.get(sid) unless sid.nil?
    nil
  end

  def signature
    if sig_sid.nil? or sig_gid.nil?
      return nil
    else
    signature = Signature.first(:sig_sid => sig_sid, :sig_gid => sig_gid)
    return signature
    end
  end 

end