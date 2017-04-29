class Lookup
  include DataMapper::Resource

  property :id, Serial

  property :title, String

  property :value, Text


  def build(args={})
    args.fetch(:ip, '')
    args.fetch(:port, '')
    value.sub(/\$\{ip\}/, "#{args[:ip]}").sub(/\$\{port\}/, "#{args[:port]}")
  end
  
  audit :title, :value do |action|
    
    if User.current_user.present?
    
      log_attributes = {:model_name => self.class, :action => action, :model_id => self.id, :user => User.current_user}

      case action.to_sym
      when :create
        log_attributes.merge!({:message => "Created #{self.class} '#{self.title}'"})
      when :update
        log_attributes.merge!({:message => changes.collect {|prop, values|
                                                            "Changed #{prop.name} from '#{values[0]}' to '#{values[1]}'"
                                                          }.join(", ")
                              })
      when :destroy
        log_attributes.merge!({:message => "Destroyed #{self.class} '#{self.title}'"})
      end

      Log.new(log_attributes).save
      
    end

  end

end
