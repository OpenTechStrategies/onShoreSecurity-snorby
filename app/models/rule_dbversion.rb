class RuleDbversion

  include DataMapper::Resource
  
  property :id, Serial, :key => true, :index => true
  property :timestamp, DateTime, :index => true, :required => true
  property :completed, Boolean, :default => false
  property :rules_count, Integer, :default => 0
  property :rules_new_count, Integer, :default => 0
  property :rules_modified_count, Integer, :default => 0
  property :rules_deprecated_count, Integer, :default => 0

  has n, :rules, :child_key => [ :dbversion_id ], :constraint => :destroy
  has n, :sensors, :child_key => [:dbversion_id ]
  has n, :dbversionSources, :child_key => [ :dbversion_id ]
  has n, :sources, :model => 'RuleSource', :through => :dbversionSources, :via => :ruleSource

  has n, :classtypes, :model => 'RuleCategory2', :child_key => :dbversion_id, :constraint => :destroy
  has n, :rule_categories2, :model => 'RuleCategory2', :child_key => :dbversion_id, :constraint => :destroy

  has n, :sensorRules, :through => :rules

  SORT = {
    :timestamp => 'dbversion',
    :id => 'dbversion'
  }
  
  audit :timestamp, :completed do |action|
    
    if User.current_user.present?
      user = User.current_user
    else
      user = User.first
    end

    log_attributes = {:model_name => self.class, :action => action, :model_id => self.id, :user => user}

    case action.to_sym
    when :create
      log_attributes.merge!({:message => "Created #{self.class} #{self.completed ? '' : 'non'} completed."})
    when :update
      log_attributes.merge!({:message => changes.collect {|prop, values| "'#{prop.name}' changed from '#{values[0]}' to '#{values[1]}'"}.join(", ")})
    end

    Log.new(log_attributes).save

  end

  def pretty_time
    return "#{self.timestamp.in_time_zone.strftime('%l:%M %p')}" if Date.today.to_date == self.timestamp.to_date
    "#{self.timestamp.in_time_zone.strftime('%d/%m/%Y')}"
  end

  def update_sensors(delayed=false)
    b = false
    if !Snorby::Jobs.sensor_update_dbversion? and !Snorby::Jobs.compilation?
      b = true
      Delayed::Job.enqueue(Snorby::Jobs::SensorUpdateDbversionJob.new(self.id, true), 
                          :priority => 15, :run_at => (delayed ? Time.now.utc.tomorrow.beginning_of_day : Time.now.utc + 10.seconds) )
    end
    b
  end

  def virtual_sensors
    sensors.select{|s| s.virtual_sensor}
  end

  def self.last_valid
    RuleDbversion.last(:completed => true)
  end

  def self.active
    dbid = Setting.find('global_dbversion_id');
    if dbid.nil?
      RuleDbversion.last(:completed => true)
    else
      RuleDbversion.get(Setting.find('global_dbversion_id'))
    end
  end

  def previous
    RuleDbversion.last(:timestamp.lt => self.timestamp, :completed=>true)
  end

  def self.current_dbversions
    Sensor.all.dbversion
  end

  def self.sorty(params={})
    sort = params[:sort]
    direction = params[:direction]

    page = {
      :per_page => User.current_user.per_page_count
    }

    #By default ruledbversion index cannot be ordered different than id
    if SORT[sort].downcase == 'dbversion'
      page.merge!(:order => sort.send(direction))
    else
      page.merge!(
        :order => [RuleDbversion.send(SORT[sort].to_sym).send(sort).send(direction)],
        :links => [RuleDbversion.relationships[SORT[sort].to_s].inverse]
      )
    end
    
    if params.has_key?(:dbversion)
          page.merge!(params[:dbversion])
    end

    page(params[:page].to_i, page)
  end

  def destroy_slowly

    if RuleDbversion.first(:completed => true) == self and Setting.find('global_dbversion_id').to_i != self.id      
      self.sensorRules.compilation.each do |c|
        c.destroy
      end

      self.sensorRules.compilation.each do |c|
        c.destroy! unless c.nil?
      end
      
      while self.sensorRules.count > 0
        sensor_rules = self.sensorRules(:limit => 100)
        sensor_rules.destroy!
      end

      self.sensorRules.destroy!

      self.rule_categories2.destroy!
      
      while self.rules.count > 0
        db_rules = self.rules(:limit => 100)
        db_rules.rule_policies.destroy!
        db_rules.rule_impacts.destroy!
        db_rules.rule_services.destroy!
        db_rules.rule_references.destroy!
        db_rules.rule_flowbits.destroy!
        db_rules.favorites.destroy!
        db_rules.destroy!
      end

      self.destroy!

      newr = RuleDbversion.first(:completed => true)
      unless newr.nil?
        newr.rules_new_count        = newr.rules_count
        newr.rules_modified_count   = 0
        newr.rules_deprecated_count = 0
        newr.save
        
        RuleDbversion.all(:id.lt => newr.id).each do |x|
          x.destroy_slowly
        end
      end

      #Deleting old not completed db_versions
    end
  end

end
