class Setting

  CHECKBOXES = [
    :utc,
    :event_notifications,
    :update_notifications,
    :daily,
    :weekly,
    :monthly,
    :lookups,
    :notes,
    :packet_capture,
    :packet_capture_auto_auth,
    :autodrop,
    :autodrop_rollback,
    :geoip,
    :show_disabled_rules,
    :flowbits_dependencies,
    :proxy
  ]

  include DataMapper::Resource

  property :name, String, :key => true, :index => true, :required => false

  property :value, Object
  
  
  audit :name, :value do |action|
    
    if User.current_user.present?
    
      log_attributes = {:model_name => self.class, :action => action, :model_id => self.name, :user => User.current_user}

      case action.to_sym
      when :update
        log_attributes.merge!({:message => changes.collect {|prop, values|

                                                            if values[0] != values[1] and CHECKBOXES.include?(name.to_sym)
                                                              "Changed #{prop.name} to '#{Setting.has_setting(name.to_sym)}'"
                                                            elsif values[0] != values[1]
                                                              "Changed #{prop.name} from '#{values[0]}' to '#{values[1]}'"
                                                            end

                                                          }.join(", ")
                              })
      end

      Log.new(log_attributes).save
      
    end

  end
  

  def checkbox?
    return true if CHECKBOXES.include?(name.to_sym)
    false
  end

  def self.set(name, value=nil)
    record = first(:name => name)
    return Setting.create(:name => name, :value => value) if record.nil?
    record.update(:value => value)
  end

  def self.find(name)
    record = first(:name => name)
    return false if record.nil?
    return false if record.value.is_a?(Integer) && record.value.zero?
    record.value
  end

  def self.has_setting(name)
    record = first(:name => name)
    return false if record.nil?
    return false if record.value.is_a?(Integer) && record.value.zero?
    return true unless record.value.blank?
    false
  end

  def self.file(name, file)
    new_file_name = file.original_filename.sub(/(\w+)(?=\.)/, "#{name}")
    new_file_path = "#{Rails.root.to_s}/public/system/#{new_file_name}"

    FileUtils.mv(file.tempfile.path, new_file_path)
    self.set(:logo, "/system/#{new_file_name}")
  end

  def self.method_missing(method, *args)
    if method.to_s.match(/^all/)
      super
    elsif method.to_s.match(/^(.*)=$/)
      return Setting.set($1, args.first)
    elsif method.to_s.match(/^(.*)\?$/)
      Setting.has_setting($1.to_sym)
    else
      return Setting.get(method.to_sym)
    end
  end

end
