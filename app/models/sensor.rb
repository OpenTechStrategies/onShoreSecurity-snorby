class Sensor
  include DataMapper::Resource
  include ActionView::Helpers::TextHelper

  MODES = {
    "Inherited" => "", 
    "IDS forwarding"       => "IDS", 
    "IDS span"             => "IDS_SPAN", 
    "IPS without rules"    => "IPS_NR", 
    "IPS with alert rules" => "IPS_ALERT", 
    "IPS test mode"        => "IPS_TEST",
    "IPS"                  => "IPS"
  }

  PREPROCESSOR_VALUES = {"Disabled" => false, "Enabled" => true, "Inherited" => ""}

  DEFAULT_ACTIONS = {
    "Inherited" => "", 
    "bypass"    => "whitelist",
    "drop"      => "blacklist",
    "analyze"   => "monitor"
  }

  after :create do |sensor|
    # After the sensor (domain or not) has been created it will involve a rule compilation for this sensor.
    #   This will create an initial restore point and it will inherit all its parents rules
    # We must create a new role for chef
    sensor.create_chef_sensor

    if sensor.virtual_sensor
      begin
        node = sensor.chef_node
        sensor.update(:ipdir => node[:ipaddress])
      rescue
        # The sensor is not found, probably because it was deleted manually and regenerated by barnyard.
      end
    end

    sensor.compile_rules(nil, true) if (!sensor.parent.nil? and sensor.domain)
  end

  after :update do |sensor|
    sensor.update_chef_sensor
  end

  before :destroy do |sensor|
    if sensor.domain
      begin
        client = sensor.chef_client
        client.destroy unless client.nil?
      rescue
        #client not found. Ignore it
      end
      begin
        node = sensor.chef_node
        node.destroy unless node.nil?
      rescue
        #node not found. Ignore it
      end
      begin
        role = sensor.chef_role
        role.destroy unless role.nil?
      rescue
        #role not found. Ignore it
      end

      begin
        if (sensor.virtual_sensor and Sensor.all(:ipdir => sensor.ipdir).count <= 1)
          sensor.disassociate_sensor 
        end
      rescue
      end
    end
  end

  storage_names[:default] = "sensor"

  property :sid, Serial, :key => true, :index => true
  property :name, String, :default => ''
  property :hostname, Text, :index => true
  property :interface, Text
  property :filter, Text

  property :detail, Integer, :index => true
  property :encoding, Integer, :index => true
  property :last_cid, Integer, :index => true
  property :events_count, Integer, :index => true, :default => 0
  property :ipdir, String
  property :domain, Boolean, :default => false
  property :virtual_sensor, Boolean, :default => false
  property :compiling, Boolean, :default => false
  property :parent_sid, Integer
  property :deleted, Boolean, :default => false

  property :num_pending_rules, Integer, :default => 0
  property :num_active_rules, Integer, :default => 0

  has n, :ips, :child_key => :sid, :constraint => :skip
  has n, :notes, :child_key => :sid, :constraint => :destroy
  has n, :events, :child_key => :sid, :constraint => :destroy!
  has n, :snmps, :child_key => :sid, :constraint => :destroy
  has n, :traps, :child_key => :sid, :constraint => :destroy
  has n, :childs, self, :constraint => :destroy, :child_key => [ :parent_sid ]
  has n, :sensorRules, :constraint => :destroy
  has n, :rules      , :through => :sensorRules
  has n, :roleSensor, :child_key => :sensor_sid, :constraint => :destroy
  has n, :roles, :through => :roleSensor
  has n, :reputations, :model => 'Reputation', :child_key => :sensor_sid, :constraint => :destroy

  has n, :event_filterings, :parent_key => :sid, :child_key => :sid, :constraint => :destroy!
  
  has n, :snort_stats, :child_key => :sid, :constraint => :destroy

  belongs_to :parent, self, :child_key => [ :parent_sid ], :required => false
  belongs_to :dbversion, :model => 'RuleDbversion', :parent_key => :id, :child_key => :dbversion_id, :required => true
  belongs_to :compilation, :model => 'RuleCompilation', :parent_key => :id, :child_key => :compilation_id, :required => false

  has n, :auto_classifications, :child_key => :sid, :constraint => :destroy

  audit :name, :parent_sid do |action|

    if User.current_user.present?
    
      log_attributes = {:model_name => self.class, :action => action, :model_id => self.sid, :user => User.current_user}

      case action.to_sym
      when :create
        log_attributes.merge!({:message => "Created #{self.class} '#{self.name}'"})
      when :update
        log_attributes.merge!({:message => changes.collect {|prop, values|
                                                              case prop.name.to_sym
                                                              when :parent_sid
                                                                "Changed parent from '#{Sensor.get(values[0]).name}' to '#{Sensor.get(values[1]).name}'"
                                                              else
                                                                "Changed #{prop.name} from '#{values[0]}' to '#{values[1]}'"
                                                              end
                                                          }.join(", ")
                              })
      when :destroy
        log_attributes.merge!({:message => "Destroyed #{self.class} #{self.name}"})
      end

      Log.new(log_attributes).save
    
    end

  end
  
  
  def cache
    Cache.all(:sid => sid)
  end
  
  def sensor_name
    if !domain
      return parent.sensor_name unless parent.nil?
    else
      return self.name unless (self.name.nil? or self.name.blank?)
      self.hostname
    end
  end

  def short_name
    sensor_name.split(".").first
  end

  def parents(include_myself=true)
    if include_myself
      result = self.parents_with_me
    else !self.is_root?
      result = self.parent.parents_with_me
    end
    result.flatten
  end

  def parents_with_me
    result = []
    unless self.is_root?
      result << self
      result << self.parent.parents_with_me
    end
    result.flatten
  end

  def path(include_myself=true)
    parents(include_myself).reverse.map{|x| x.name}.join('/')
  end
  
  def daily_cache
    DailyCache.all(:sid => sid)
  end

  def last
    if domain
      childs.map(&:last).select{|s| s and s.valid?}.sort{|x, y| y.timestamp <=> x.timestamp}.first unless childs.blank?
    else
      return Event.get(sid, last_cid) unless last_cid.blank?
      false
    end
  end

  def last_pretty_time
    return "#{self.last.timestamp.strftime('%l:%M %p')}" if Date.today.to_date == self.last.timestamp.to_date
    "#{self.last.timestamp.strftime('%d/%m/%Y')}"
  end
  
  def event_percentage
    begin
      total_event_count = Sensor.all(:virtual_sensor => true).map(&:events_count).sum
      "%.2f" % ((self.events_count.to_f / total_event_count.to_f) * 100).round(1)
    rescue FloatDomainError
      0
    end
  end

  def self.compile_rules(sensor_sid, user_id, compilation_ob, updated_parent)
    errors = false
    sensor = Sensor.get(sensor_sid)
    if compilation_ob.class == RuleCompilation
      compilation  = compilation_ob
    else
      compilation  = RuleCompilation.create(:name => compilation_ob.to_s, :sensor => sensor, :timestamp => Time.now, :user => User.get(user_id))
    end
    SensorRule.transaction do |t|
      begin
        sensor.compile_rules(compilation, true)
      rescue DataObjects::Error => e
        errors = true
        t.rollback
      end
    end

    sensor = Sensor.get(sensor_sid)
    sensor.update(:num_pending_rules => sensor.pending_rules.count, :num_active_rules => sensor.last_compiled_rules.count)

    sensor.all_childs.each do |s|
      s.update(:num_pending_rules => s.pending_rules.count, :num_active_rules => s.last_compiled_rules.count)
    end

  end

  def update_compilation(compilation)
    if domain
      self.childs.each do |s|
        s.update_compilation(compilation)
      end		
      self.update(:compilation_id => compilation.id)
    end
  end

  # This method will compile the rules saving the pending rules. It will involve the compilation of all sensor included in this domain.
  def compile_rules(compilation=nil, first_time=true)
    if domain and !deleted
      if compilation.nil?
        parent_rules = (self.parent.nil? or self.parent.last_compiled_rules.blank?) ? SensorRule.all(:id=>0) : self.parent.last_compiled_rules
        compilation  = RuleCompilation.create(:timestamp => Time.now, :name => "Automatic compilation", :sensor => self, :user => User.current_user) if compilation.nil?
      else
        if self.parent.nil?
          parent_rules = SensorRule.all(:id => 0)
        elsif first_time
          parent_rules = self.parent.last_compiled_rules
        else
          parent_rules = self.parent.compiled_rules(compilation.id)
        end
      end

      pending_rules_copy         = self.pending_rules
      last_compilation_copy      = self.last_compilation
      last_compiled_rules_copy   = last_compilation_copy.nil? ? SensorRule.all(:id => 0) : self.compiled_rules(last_compilation_copy.id)
      rules_ids                  = []  #evita duplicados
      same_compilation           = false

      if (!last_compilation_copy.nil? and !compilation.nil? and last_compilation_copy.id == compilation.id)
        #En principio, esto puede pasar en un rollback solamente
        #Las reglas ya compiladas no hace falta volverlas a meter
        rules_ids = last_compiled_rules_copy.all(:inherited => false).rules.map(&:rule_id).uniq
        same_compilation = true
      end

      # Insertamos las nuevas reglas del padre
      parent_rules.each do |sr|
        if !rules_ids.include?(sr.rule_id)
          if !sr.allow_overwrite
            rules_ids << sr.rule_id
            pr = SensorRule.create(sr.attributes.merge(:id => nil, :sensor_sid => self.sid, :compilation => compilation, :inherited => true, :allow_overwrite => false))
          else
            # Solo lo insertamos si no esta en las reglas en las ultimas reglas compiladas o en las reglas pendientes
            prc = pending_rules_copy.first(:rule => sr.rule)
            if prc.nil?
              last_sr = last_compiled_rules_copy.first(:rule=>sr.rule)
              if last_sr.nil?
                #no esta compilada de antes luego siempre es heredada
                rules_ids << sr.rule_id
                pr = SensorRule.create(sr.attributes.merge(:id => nil, :sensor_sid => self.sid, :compilation => compilation, :inherited => true))
              else
                if last_sr.inherited or last_sr.action.inherited?
                  #esta compilada de antes pero es heredada luego debe ser sobreescrita por la nueva
                  rules_ids << sr.rule_id
                  pr = SensorRule.create(sr.attributes.merge(:id => nil, :sensor_sid => self.sid, :compilation => compilation, :inherited => true))
                end
              end
            elsif prc.action.inherited?
              rules_ids << sr.rule_id
              pr = SensorRule.create(sr.attributes.merge(:id => nil, :sensor_sid => self.sid, :compilation => compilation, :inherited => true))
            end
          end
        elsif same_compilation and !sr.allow_overwrite
          pr = SensorRule.create(sr.attributes.merge(:id => nil, :sensor_sid => self.sid, :compilation => compilation, :inherited => true, :allow_overwrite => false))
          last_sr = last_compiled_rules_copy.first(:rule => sr.rule)
          last_sr.destroy unless last_sr.nil?
          last_compiled_rules_copy.reload
        end
      end

      
      #Insertamos las reglas de la compilación anterior si procede que no sean heredadas
      last_compiled_rules_copy.all(:inherited => false).each do |sr|
        if !rules_ids.include?(sr.rule_id)
          # Solo lo insertamos si no esta en las reglas pendientes
          if pending_rules_copy.first(:rule => sr.rule).nil? and !sr.action.inherited?
            rules_ids << sr.rule_id
            pr = SensorRule.create(sr.attributes.merge(:id => nil, :sensor_sid => self.sid, :compilation => compilation))
          end
        end
      end

      # Añadimos las reglas pendientes que procedan
      pending_rules_copy.each do |sr|
        if !rules_ids.include?(sr.rule_id) and !sr.action.inherited?
          sr.update(:compilation => compilation)
        else
          sr.destroy
        end
      end
    
      Sensor.get(sid).update(:compilation_id => compilation.id)

      self.childs.select{|s| !s.deleted}.each do |s|
        s.compile_rules(compilation, false)
      end		
    end
  end

  # Returns an array with all pending rules (not compiled). 
  def pending_rules
    sensorRules.all(:compilation => nil)
  end

  # Return the last compilation object for this sensor
  def last_compilation
    lc = self.compilation
    lc = RuleCompilation.get(self.sensorRules.max(:compilation_id)) if lc.nil?
    lc
  end

  # Return an array with the rules for the compilation passed as the argument 
  def compiled_rules(compilation_id)
    self.sensorRules.all(:compilation_id => compilation_id, :order => [:rule_id.asc])
  end

  # Return an array with the rules for the compilation passed as the argument
  def last_rules(compilation_id = nil)
    if compilation_id.nil?
      lc = last_compilation
      if lc.nil?
        #seria las reglas pendientes
        result = self.sensorRules.all(:compilation => lc)
      else
        result = (self.sensorRules.all(:compilation => lc) | self.sensorRules.all(:compilation_id => nil))
      end
    else
      result = self.sensorRules.all(:compilation_id => compilation_id)
    end
    result
  end

  # Return an array with the rules for the last compilation (the oldest modifications)
  def last_compiled_rules
    self.last_compilation.nil? ? SensorRule.all(:id => 0) : self.compiled_rules(self.last_compilation.id)
  end

  def rollback_last_rules(index=1)
    c = self.compilations
    unless c.nil?
      if c.size > index
        Delayed::Job.enqueue(Snorby::Jobs::RollbackJob.new(sid, c[c.size - index - 1].id, User.current_user.id, true),
                            :priority => 1,
                            :run_at => Time.now + 5.seconds)
      end
    end
  end

  # The sensor will insert a list of pending rules included in the compilation passed.
  def self.rollback_rules(sensor_sid, compilation_id, user_id=nil)
    sensor = Sensor.get(sensor_sid.to_i)
    compilation = RuleCompilation.get(compilation_id.to_i)
    user = user_id.nil? ? User.current_user : User.get(user_id)

    if sensor.domain && !compilation.nil?
      new_compilation = RuleCompilation.create(:timestamp => Time.now, :sensor => sensor, :user => user, :name => "Rollback - #{compilation.name}".truncate(50))
      unless new_compilation.nil?
        SensorRule.transaction do |t|
          begin
            sensor.rollback_rules(compilation, user, new_compilation)
          rescue DataObjects::Error => e
            t.rollback
          end
        end
      end
    end
    new_compilation
  end

  def rollback_rules(compilation, user, new_compilation)
    self.pending_rules.each{|x| x.destroy}
    SensorRule.all(:sensor_sid => self.sid, :compilation_id => compilation.id, :inherited => false).each do |sr|
      #es posible que haya que actualizar dicha regla a la version de reglas del sensor
      attributes = sr.attributes.merge(:id => nil, :compilation => new_compilation, :user => user) 
      if sr.rule.dbversion.id != self.dbversion 
        #hay que actualizar dicha regla a la nueva version
        updated_rule = self.dbversion.rules.first(:rule_id => sr.rule.rule_id, :gid=>sr.rule.gid)
        if updated_rule.nil?
          attributes = nil
        else
          attributes = attributes.merge(:rule_id => updated_rule.id)
        end
      end
      SensorRule.create(attributes) unless attributes.nil?
    end

    self.childs(:domain => true).each do |s|
      s.rollback_rules(compilation, user, new_compilation)
    end

    self.update(:compilation => new_compilation, :num_pending_rules => 0, :num_active_rules => self.last_rules(new_compilation.id).size)
  end


  def hierarchy(deep)
    sensors = childs.all(:order => [:name.asc], :domain => true).to_a unless childs.blank?
		
    if !sensors.nil? and deep > 1 
      sensors.each_with_index do |x, index|
        sensors[index] = [x, x.hierarchy(deep - 1)] unless x.nil? or x.childs.blank?
      end
    end

    sensors
  end

  def events_count
    if domain
      count = 0
      childs.each do |x| 
        tmp_var=x.events_count
        count += x.events_count unless tmp_var.nil?
      end
      count
    else
      super
    end
  end

  # Return an array with all real sensors for this sensor.
  def real_sensors
    (childs.map{|x| x.domain ? x.real_sensors : x}.flatten.compact unless self.childs.blank?) or []
  end

  # Return an array with all childs virtual sensors for this sensor, including self sensor.
  def virtual_sensors(include_deleted=true)
    sensors = []
    if virtual_sensor
      sensors << self unless !include_deleted and self.deleted
    else
      sensors = childs.map do |x|
        if x.domain
          x.virtual_sensors(include_deleted)
        end
      end
    end

    sensors.flatten.compact
  end

  def compilations
    sensorRules.compilations
  end

  def deep
    parent.nil? ? 0 : 1 + parent.deep
  end

  # Args is used for accept arguments like sensor.events(:timestamp.gte => Time.now.yesterday)
  def events(args={})
    if domain
      Event.all(args.merge!(:sid => real_sensors.map(&:sid)))
    else
      super(args)
    end
  end

  # Return the root sensor (first parent)
  def self.root
    Sensor.first(:name => "root")
  end

  def is_root?
    parent.nil? and self.name == 'root'
  end

  def parent_domain
    p = parent
    unless p.nil?
      p = p.parent unless domain?
    end

    return p
  end

  def get_parents_string



  end

  # Return nil if this rule is not pending.
  # In case this rule is pending it will return the sensorRule asociated
  def pending_rule?(rule)
    self.pending_rules.first(:rule => rule)
  end

  def discard_pending_rules
    SensorRule.transaction do |t|
      begin
        pending_rules.destroy
        self.update(:num_pending_rules => 0)
      rescue DataObjects::Error => e
        t.rollback
      end
    end
  end

  def reset_rules
    SensorRule.transaction do |t|
      begin
        pending_rules.destroy
        self.update(:num_pending_rules => 0)

        inherited_action = RuleAction.first(:name => 'inherited')
        own_rules        = self.last_compiled_rules.all(:inherited => false)
        own_rules.each do |sr|
          sr2 = SensorRule.create(:sensor => self, :rule => sr.rule, :action => inherited_action, :user => User.current_user)
        end
        self.update(:num_pending_rules => own_rules.size)
      rescue DataObjects::Error => e
        t.rollback
      end
    end
  end

  def action_for_rule(rule, last_rules=nil)
    action = nil
    if last_rules.nil?
      sr     = self.pending_rules.first(:rule => rule)
      if sr.nil?
        lcr = self.last_compiled_rules
        unless lcr.empty?
          sr = lcr.first(:rule => rule)
          action = sr.action unless sr.nil?
        end
      else
        action = sr.action
      end
    else
      sr = last_rules.last(:rule => rule)
      action = sr.action unless sr.nil?
    end
    action
  end

  def action_str_for_rule(rule, last_rules=nil)
    action = ""
    if last_rules.nil?
      sr     = self.pending_rules.first(:rule => rule)
      if sr.nil?
        lcr = self.last_compiled_rules
        unless lcr.empty?
          sr = lcr.first(:rule => rule)
          action = sr.action.name unless sr.nil?
        end
      else
        action = sr.action.name
      end
    else
      sr = last_rules.last(:rule => rule)
      action = sr.action.name unless sr.nil?
    end
    action
  end

  def chef_name
    if domain
      "#{Snorby::CONFIG[:chef_prefix]}-rBsensor-#{self.sid}"
    else
      self.parent.chef_name
    end
  end

  def self.chef_sensor_role
    Chef::Role.load("sensor")
  end

  def self.chef_manager_role
    Chef::Role.load("manager")
  end

  def chef_role
    Chef::Role.load(self.chef_name)
  end

  def self.manager_chef_role
    Chef::Role.load("manager")
  end

  def chef_node
    if self.virtual_sensor
      Chef::Node.load(self.hostname)
    end
  end

  def self.manager_chef_node
    Chef::Node.load("rb-manager")
  end

  def chef_client
    if self.virtual_sensor
      Chef::ApiClient.load(self.hostname)
    end
  end

  def create_chef_sensor
    if self.domain
      role = Chef::Role.new
      set_default_chef_role_params(role)
      role.create
    end
  end

  def update_chef_sensor
    if self.domain
      role = self.chef_role
      set_default_chef_role_params(role)
      role.save

      if self.virtual_sensor
        #we have to update the node
        node = self.chef_node
        unless node.nil?
          node.run_list("role[#{self.chef_name}]")
          node.save
        end
      end
    end
  end

  def destroy_chef_role
    if self.domain
      if self.virtual_sensor
        node = self.chef_node
        node.destroy unless node.nil?
      end

      role = self.chef_role
      role.destroy unless role.nil?
    end
  end

  def self.repair_chef_db
#    Sensor.all(:domain=>true, :virtual_sensor => true).each do |sensor|
#      begin
#        sensor.chef_node
#      rescue Net::HTTPServerException
#        sensor.destroy
#      end
#    end

    Sensor.all(:domain=>true).each do |sensor|
      begin
        #p "Default values for #{sensor.name} (id: #{sensor.sid})"
        sensor.update_chef_sensor
      rescue Net::HTTPServerException
        sensor.create_chef_sensor
      end
    end

    Chef::Role.list.each do |array|
      match = /^#{Snorby::CONFIG[:chef_prefix]}-rBsensor-([0-9]+)$/.match(array[0])
      unless match.nil?
        sensor = Sensor.get(match[1])
        sensor = nil if !sensor.nil? and !sensor.domain
        if sensor.nil?
          Chef::Role.load(array[0]).destroy
        end
      end
    end
  end

  def role_value(attributes)
    if !self.domain
      return nil
    end

    value = chef_role.override_attributes

    attributes.each do |k|
      value.has_key? k ? value = value[k] : value = nil
      if value.nil?
        break
      end
    end

    if (value.nil? or ((value.class==Array or value.class==Hash) and !value.present? ))
      if parent
        value = parent.role_value(attributes)
      else
        value = Sensor.chef_sensor_role.override_attributes
        attributes.each do |k|
          value.has_key? k ? value = value[k] : value = nil
          if (value.nil? or ((value.class==Array or value.class==Hash) and !value.present? ))
            break
          end
        end
      end
    end
    value
  end

  # Return a Net::SSH object connected to the generic device
  def get_connection_ssh()
    #require 'net/ssh'
    unless self.ipdir.nil? || self.ipdir.empty?
      Net::SSH::Transport::Algorithms::ALGORITHMS[:encryption] = %w(aes128-cbc 3des-cbc blowfish-cbc cast128-cbc
      aes192-cbc aes256-cbc none arcfour128 arcfour256 arcfour
      aes128-ctr aes192-ctr aes256-ctr cast128-ctr blowfish-ctr 3des-ctr)
      ssh = Net::SSH.start(
        self.ipdir,                     # internal ip
        "redBorder",                    # username
        :auth_methods => ["publickey"], # auth method
        :paranoid => false,
        :timeout => 5,
        :keys => ["config/#{Snorby::CONFIG[:rsa_filename]}"],
        :config => false,
        :user_known_hosts_file => []
      )
    end
    ssh
  end
  
  def uploadGeoIp(reload=true)
    upload("config/snorby-geoip.dat", "GeoIP.dat.new") do |ssh|
      ssh.exec("sudo /bin/rb_update_geoip #{reload ? "-r" : "" }")
    end
  end

  def upload(local_file, remote_file)
    if !self.ipdir.nil? and !self.ipdir.empty? and self.virtual_sensor?
      Net::SSH.start(
        self.ipdir, 
        "redBorder",
        :auth_methods => ["publickey"], # auth method
        :paranoid => false,
        :timeout => 5,
        :keys => ["config/#{Snorby::CONFIG[:rsa_filename]}"],
        :config => false,
        :user_known_hosts_file => []
      ) do |ssh|
        ssh.scp.upload!(local_file, remote_file)
        yield(ssh) if block_given?
      end
    else
      self.virtual_sensors.each do |sensor|
        sensor.upload(local_file, remote_file)
      end
    end
  end

  def execute(commands)
    ssh = get_connection_ssh
    unless ssh.nil?
      if commands.respond_to?('each')
        commands.each do |cmd|
          ssh.exec(cmd)
        end
      else
        ssh.exec(commands.to_s) unless commands.nil?
      end
      ssh.close
    end
  end

  def execute_sorted(commands)
    ssh = get_connection_ssh
    unless ssh.nil?
      if commands.respond_to?('each')
        commands.each do |cmd|
          ssh.exec!(cmd)
        end
      else
        ssh.exec!(commands.to_s) unless commands.nil?
      end
      ssh.close
    end
  end

  #return all sensor childs up to virtual sensors.
  def all_childs(including_self=false, including_real_sensors=false)
    
    sensors = []
    
    if !domain and !including_real_sensors
      return sensors
    elsif !domain and including_real_sensors
      sensors << self
    elsif including_self
      sensors << self
    end
    
    sensors << childs.map{|x| x.all_childs(true, including_real_sensors)}
    sensors.flatten.uniq
  end

  def self.update_all_dbversion(dbversion_id)

    dbversion = RuleDbversion.get(dbversion_id)

    return if dbversion.nil?

    Sensor.all.each do |sensor|
      need_update = false

      if sensor.dbversion_id != dbversion.id
        need_update = true
      else
        # It verifies that rules are propertly configured
        active_rules = sensor.last_rules
        dbversions   = active_rules.rules.dbversion
        if dbversions.size <= 1
          need_update = false   #the sensor has no rules to update.
        else
          need_update = true
        end
      end

      if need_update
        sensor.update_dbversion(dbversion.id)
      end
    end
    
    Setting.set(:global_dbversion_id, dbversion.id)

  end

  def update_dbversion(dbversion_id=nil)
    
    rule_dbversion = if dbversion_id.nil?
      RuleDbversion.last(:completed => true)
    else
      RuleDbversion.get(dbversion_id)
    end

    return if rule_dbversion.nil? or !rule_dbversion.completed

    SensorRule.transaction do |t|
      begin
        last_rules.each do |sr|
          new_rule = Rule.last(:dbversion => rule_dbversion, :rule_id => sr.rule.rule_id, :gid => sr.rule.gid) unless sr.rule.nil?

          if new_rule.nil?
            sr.destroy
          else
            sr.rule = new_rule
            sr.save
          end
        end
        # self.update(:dbversion => rule_dbversion, :num_active_rules => last_rules.size)
        self.dbversion = rule_dbversion
        self.num_active_rules = last_rules.size
        self.save
      rescue DataObjects::Error => e
        t.rollback
      end
    end
    
  end

  def download_rules
    if self.virtual_sensor?
      self.execute("sudo /bin/rb_get_sensor_rules.sh -d #{self.dbversion.nil? ? 1 : self.dbversion.id}")
    else
      self.virtual_sensors.each do |sensor|
        sensor.download_rules
      end
    end
  end

  def wakeup_chef
    if self.virtual_sensor?
      self.execute("sudo /etc/init.d/chef-client wakeup")
    else
      self.virtual_sensors.each do |sensor|
        sensor.wakeup_chef
      end
    end
  end

  def disassociate_sensor
    self.execute("sudo /bin/rb_disassociate_sensor.sh -f")
  end

  def check_warnings(rules=nil)
    rules = last_rules.rule if rules.nil?
    flow_isset = Flowbit.first(:name => "isset")
    flow_set   = Flowbit.first(:name => "set")

    isset_state = rules.rule_flowbits(:flowbit_id => flow_isset.id).map(&:state_id).uniq
    set_state   = rules.rule_flowbits(:flowbit_id => flow_set.id).map(&:state_id).uniq
    states      = (isset_state - set_state).map{|s| FlowbitState.get(s)}
    warnings    = []

    states.each do |state|
      warnings << state.name
    end

    warnings

  end

  def check_errors(rules=nil)
    rules = last_rules.rule if rules.nil?
    errors = []
    if !role_value(["redBorder", "snort", "preprocessors", "dcerpc2", "mode"])
      if rules(:conditions => ['rule LIKE ? OR rule LIKE ? OR rule LIKE ?', "%; dce_stub_data:%", "%; dce_iface:%", "%; dce_opnum:%"]).present?
        errors << "dcerpc2"
      end
    end

    if !role_value(["redBorder", "snort", "preprocessors", "ssl", "mode"])
      if rules(:conditions => ['rule LIKE ? OR rule LIKE ?', "%; ssl_state:%", "%; ssl_version:%"]).present?
        errors << "ssl"
      end
    end

    errors
  end

  def check_preprocessor(preprocessor)
    rules = last_rules.rule

    case preprocessor
    when "modbus"
      return rules(:conditions => ['rule LIKE ? OR rule LIKE ? OR rule LIKE ?', "%; modbus_func:%", "%; modbus_unit:%", "%; modbus_data:%"]).blank?
    when "sensitive"
      return rules(:conditions => ['rule LIKE ?', "%; sd_pattern:%"]).blank?
    when "dcerpc2"
      return rules(:conditions => ['rule LIKE ? OR rule LIKE ? OR rule LIKE ?', "%; dce_stub_data:%", "%; dce_iface:%", "%; dce_opnum:%"]).blank?
    when "ssl"
      return rules(:conditions => ['rule LIKE ? OR rule LIKE ?', "%; ssl_state:%", "%; ssl_version:%"]).blank?
    when "sip"
      return rules(:conditions => ['rule LIKE ? OR rule LIKE ? OR rule LIKE ? OR rule LIKE ?', "%; sip_method:%", "%; sip_stat_code:%", "%; sip_header:%", "%; sip_body:%"]).blank?
    when "dnp3"
      return rules(:conditions => ['rule LIKE ? OR rule LIKE ? OR rule LIKE ? OR rule LIKE ?', "%; dnp3_func:%", "%; dnp3_obj:%", "%; dnp3_ind:%", "%; dnp3_data:%"]).blank?
    when "normalize"
      return !role_value(["redBorder", "snort", "mode"]).start_with?("IPS")
    else
      return true
    end

  end

  def self.current_dbversions
    Sensor.all(:sid.not => 1).dbversion
  end
  
  def self.sorty(params={})
    sort = params[:sort]
    direction = params[:direction]

    page = {
      :per_page => User.current_user.per_page_count
    }
    
    page.merge!(:domain => true, :virtual_sensor => true)
    page.merge!(:order => sort.send(direction))

    page(params[:page].to_i, page)
  end

  def self.old_compilations
    array = [ 1 ]
    if Setting.autodrop_rollback?
      max   = Setting.find('autodrop_rollback_count').to_i
    else
      max = 0
    end

    if (max > 0)
      Sensor.all(:domain => true, :sid.not => Sensor.root.sid).each do |sensor|
        sensor.compilations.all(:order=>:timestamp.desc).each_with_index do |c, i|
          if i<max
            array << c.id unless array.include?(c.id)
          end
        end
      end
      RuleCompilation.all(:id.not => array)
    else
      #infinite
      RuleCompilation.all(:id => 0)
    end
  end

=begin
  def override_pending_rule(rule_id, gid, action)
    rule_action = RuleAction.first(:name => action)
    rule = last_rules.rules.first(:rule_id => rule_id, :gid => gid)
    if rule.nil?
      rule = dbversion.rules.first(:rule_id => rule_id, :gid => gid)
      SensorRule.create(:sensor => self, :rule => rule, :action => rule_action, :user => User.current_user)
      return 1
    elsif last_rules.first(:rule => rule).action != rule_action and last_rules.first(:rule => rule).compilation.nil?
      last_rules.first(:rule_id => rule.id).update(:action => rule_action, :compilation_id => nil)
      return 1
    elsif last_rules.first(:rule => rule).action != rule_action
      SensorRule.create(:sensor => self, :rule => rule, :action => rule_action, :user => User.current_user)
      return 1
    end

    return 0
  end
=end

  def override_pending_rule(rule_id, gid, action)
    rule_action = RuleAction.first(:name => action)
    rule        = dbversion.rules.first(:rule_id => rule_id, :gid => gid)
    sensor_rule = last_rules.first(:rule => rule)

    if rule.present?
      if sensor_rule.nil?
        SensorRule.create(:sensor => self, :rule => rule, :action => rule_action, :user => User.current_user)
        return 1
      elsif sensor_rule.action != rule_action and sensor_rule.compilation
        SensorRule.create(:sensor => self, :rule => rule, :action => rule_action, :user => User.current_user)
        return 1
      elsif sensor_rule.action != rule_action and sensor_rule.compilation.nil?
        sensor_rule.update(:action => rule_action)
        return 1
      end
    end

    return 0

  end

  def limits
    
  end

  def bwlist_reputations_countries
    type=2
    result = self.reputations.all(:type_id => type, :order => :position).to_a
    values = result.map{|f| f.country_id}

    self.parents(false).each do |sensor|
      if values.present?
        result.concat(sensor.reputations.all(:type_id => type, :country_id.not => values, :order => :position ).to_a)
      else
        result.concat(sensor.reputations.all(:type_id => type, :order => :position ).to_a)
      end
      values.concat(result.map{|f| f.country_id})
    end
    result
  end

  def bwlist_reputations_ipnets
    type=1
    result = self.reputations.all(:type_id => type, :order => :position).to_a
    values = result.map{|f| f.value}

    self.parents(false).each do |sensor|
      if values.present?
        result.concat(sensor.reputations.all(:type_id => type, :value.not => values, :order => :position ).to_a)
      else
        result.concat(sensor.reputations.all(:type_id => type, :order => :position ).to_a)
      end
      values.concat(result.map{|f| f.value})
    end
    result
  end

  def limit_events_rules
    thresholds("limit")
  end

  def suppress_events_rules
    thresholds("suppress")
  end

  def all_events_rules
    thresholds(["limit", "suppress"])
  end

  def thresholds(filtering_type)
    result    = self.event_filterings.all(:order => :position, :filtering_type => filtering_type).to_a
    condition = ""
    result.each do |x|
      condition << "AND " if condition != ""
      condition << "!(sig_sid=#{x.sig_sid} AND sig_gid=#{x.sig_gid}) "
    end

    self.parents(false).each do |sensor|
      if condition.present?
        result.concat(sensor.event_filterings.all(:order => :position, :filtering_type => filtering_type, :conditions => [ condition ] ).to_a)
      else
        result.concat(sensor.event_filterings.all(:order => :position, :filtering_type => filtering_type ).to_a)
      end

      condition = ""
      result.each do |x|
        condition << "AND " if condition != ""
        condition << "!(sig_sid=#{x.sig_sid} AND sig_gid=#{x.sig_gid}) "
      end
    end
    result
  end

  def save_reputations_chef
    saved = false
    if self.virtual_sensor?
      node = self.chef_node

      unless node.nil?
        node.set[:redBorder] = {} if node[:redBorder].nil?
        node.set[:redBorder][:snort] = {} if node[:redBorder][:snort].nil?
        node.set[:redBorder][:snort][:iplist] = [] if node[:redBorder][:snort][:iplist].nil?
        node.set[:redBorder][:snort][:countrylist] = [] if node[:redBorder][:snort][:iplist].nil?

        chef_array = []
        self.bwlist_reputations_ipnets.each  {|fw| chef_array << fw.relevant_fields }
        node.set[:redBorder][:snort][:iplist] = chef_array

        chef_array = []
        self.bwlist_reputations_countries.each { |fw| chef_array << fw.relevant_fields }
        node.set[:redBorder][:snort][:countrylist] = chef_array       

        saved = node.save
      end
    else
      self.virtual_sensors.each do |sensor|
        sensor.save_reputations_chef
      end
    end
    saved
  end  


  def save_thresholds_chef
    saved = false
    if self.virtual_sensor?
      node = self.chef_node

      unless node.nil?
        node.set[:redBorder] = {} if node[:redBorder].nil?
        node.set[:redBorder][:snort] = {} if node[:redBorder][:snort].nil?
        node.set[:redBorder][:snort][:events_rules] = {} if node[:redBorder][:snort][:events_rules].nil?
        node.set[:redBorder][:snort][:events_rules][:limit]    = [] if node[:redBorder][:snort][:events_rules][:limit].nil?
        node.set[:redBorder][:snort][:events_rules][:suppress] = [] if node[:redBorder][:snort][:events_rules][:suppress].nil?

        chef_array = []
        self.limit_events_rules.each  {|x| chef_array << x.relevant_fields }
        node.set[:redBorder][:snort][:events_rules][:limit] = chef_array

        chef_array = []
        self.suppress_events_rules.each  {|x| chef_array << x.relevant_fields }
        node.set[:redBorder][:snort][:events_rules][:suppress] = chef_array

        saved = node.save
      end
    else
      self.virtual_sensors.each do |sensor|
        sensor.save_thresholds_chef
      end
    end
    saved
  end 

  def last_check_in_msg(node=nil)
    status_msg = "Unknown"
    if self.virtual_sensor?
      node = self.chef_node if node.nil?
      if !node.nil? and !node[:ohai_time].nil?
        hours, minutes, seconds = time_difference_in_hms(self.chef_node[:ohai_time])

        if hours > 24
          status_msg = "#{hours/24} days ago"
        elsif hours > 0
          status_msg = "#{pluralize(hours, 'hour')} ago"
        elsif minutes < 1
          status_msg = "< 1 minute ago"
        else
          status_msg = "#{pluralize(minutes, 'minute')} ago"
        end
      end
    end

    status_msg
  end

  def time_difference_in_hms(unix_time)
    now = Time.now.to_i
    difference = now - unix_time.to_i
    
    mm, ss = difference.divmod(60)
    hh, mm = mm.divmod(60)

    return [hh, mm, ss]
  end

  private

  def set_default_chef_role_params(role)
    unless role.nil?
      role.name(self.chef_name)
      #role.description(self.sensor_name)      # la descripcion da problemas para cambiarse
      role.override_attributes["redBorder"] ||= {}
      role.override_attributes["redBorder"]["role"]  = role.name
      role.override_attributes["redBorder"]["snort"] ||= {}
      role.override_attributes["redBorder"]["snort"]["preprocessors"] ||= {}
      role.override_attributes["redBorder"]["snort"]["ipvars"] ||= {}
      role.override_attributes["redBorder"]["snort"]["portvars"] ||= {}
      role.override_attributes["redBorder"]["snort"]["segments"] ||= []
      role.override_attributes["redBorder"]["syslog-ng"] ||= {}
      role.override_attributes["redBorder"]["syslog-ng"]["servers"] ||= []
      role.override_attributes["redBorder"]["syslog-ng"]["protocol"] ||= "tcp"
      role.override_attributes["redBorder"]["snmp"] ||= {}
      role.override_attributes["redBorder"]["snmp"]["trap_servers"] ||= []
      role.override_attributes["redBorder"]["smtp"] ||= {}
      role.override_attributes["redBorder"]["smtp"]["relayhost"] = "" 

      if self.parent.nil? or self.is_root?
        role.run_list("role[sensor]")
      else
        role.run_list("role[#{self.parent.chef_name}]")
      end
    end
  end  
end