class SensorsController < ApplicationController

  respond_to :html, :xml, :json, :js, :csv

  #before_filter :require_administrative_privileges, :except => [:index, :update_name]
  before_filter :create_virtual_sensors, :only => [:index]
  before_filter :check_compilation_jobs, :only => [:index]

  before_filter :default_values, :except => [:index, :new, :create, :search]

  authorize_resource :except => [:index, :update_dashboard_hardware, :update_dashboard_load, :update_dashboard_rules, :update_dashboard_segments, :search, :bypass, :new_trap, :add_trap, :delete_trap]
  
  # It returns a sensor's hierarchy tree
  def index
    hierarchy = Sensor.root.hierarchy(10)
    @sensors = []
    @sensors = hierarchy.flatten.compact.select{|s| can?(:read, s) and !s.deleted} unless hierarchy.nil?
  end

  def show
    # @range  = 'last_24'
    # cache = Cache.all(:sensor => @sensor.all_childs(true, true)).last_24(Time.now.yesterday, Time.now)
    # event_values(cache)

    # snmp_values
    # traps_values

    # if @sensor_metrics.last
    #   @axis = @sensor_metrics.last[:range].join(',')
    # elsif @metrics.first.last
    #   @axis = @metrics.first.last[:range].join(',')
    # end

    @range  = 'last_24'
    @now    = Time.now
    
    @cache = Cache.all(:sensor => @sensor.all_childs(true, true)).last_24(@now.yesterday, @now)
    @axis  = Cache.count_hash(@range.to_sym).keys.collect {|x| "'#{x.split('-').last}'" }.join(',')

    #snmp_values
    
    traps_values
    
    @new_tabs = Event::AGGREGATED_COLUMNS.reject{|k, v| current_user.dashboardTabs.map(&:column).include?(k.to_s)}.sort{|a1,a2| a1[1]<=>a2[1]}.to_a
    @tabs = []
    current_tabs = current_user.dashboardTabs(:order => [:position.asc])

    if current_tabs.length == 0
      current_user.dashboardTabs << DashboardTab.new(:column => "SENSOR")
      current_user.save
      current_tabs = current_user.dashboardTabs(:order => [:position.asc])
    end    

    active_tab    = current_tabs.first(:column => session[:tab].to_s) unless session[:tab].nil?
    session[:tab] = current_tabs.first.column if active_tab.nil?

    current_tabs.each do |tab|
      if session[:tab].to_s == tab.column.to_s
        set_metric(tab.column.to_sym)
      end
      @tabs << {:column => tab.column.to_sym, :name => Event::AGGREGATED_COLUMNS[tab.column.to_sym]}        
    end
  end

  def update_name
    @sensor.update(:name => params[:name]) if @sensor
    render :text => @sensor.name
  end

  def update_ip
    @sensor.update(:ipdir => params[:ip]) if @sensor
    render :text => @sensor.ipdir
  end

  def update_dashboard_rules
    authorize! :read, @sensor
    @events = @sensor.events(:order => [:timestamp.desc], :limit => 10)
    @traps  = @sensor.traps(:order => [:timestamp.desc], :limit => 5)
  end

  def update_dashboard_load
    authorize! :read, @sensor
    snmp_values
  end
  
  def update_dashboard_hardware
    authorize! :read, @sensor
  end

  def update_dashboard_segments
    authorize! :read, @sensor
    segments_values
  end

  # It destroys a sensor and its childs.
  def destroy
    @sensor.all_childs(true, true).each{|s| s.update(:deleted => true)}
    Delayed::Job.enqueue(Snorby::Jobs::DeleteSensorJob.new(@sensor.sid, User.current_user.id, true),
                        :priority => 5,
                        :run_at => Time.now + 5.seconds)
    respond_to do |format|
      format.html { redirect_to(sensors_path) }
      format.xml  { head :ok }
    end
  end

  def new
    @sensor = Sensor.new
    render :layout => false
	end

  def create
    params[:sensor][:domain]=true if params[:sensor][:domain].nil?
    params[:sensor].merge!(:dbversion   => RuleDbversion.active)
    params[:sensor].merge!(:compilation => RuleCompilation.first)
    params[:sensor].merge!(:parent => Sensor.root)
    params[:sensor].merge!(:domain => true)
    @sensor = Sensor.create(params[:sensor])
    redirect_to sensors_path
  end

  def edit
    @role = @sensor.chef_role
    @node = @sensor.chef_node
    @snort_initialized = @role.override_attributes["redBorder"]["snort"]["initialized"]
    @snort_segments = @role.override_attributes["redBorder"]["snort"]["segments"]
  end

  def update
    @role = @sensor.chef_role

    params_role = params[:role]

    params[:sensor] ||= {:name => @sensor.name}

    @role.override_attributes["redBorder"]["snort"]["segments"] = [] if params_role[:redBorder][:snort][:segments].nil?
    
    params_role[:redBorder][:snort].each do |key, value|
      if value.class == ActiveSupport::HashWithIndifferentAccess
        value.each do |key2, value2|
          if key == "preprocessors"
            value2["mode"].present? ? @role.override_attributes["redBorder"]["snort"][key][key2] = to_boolean(value2) : @role.override_attributes["redBorder"]["snort"][key].delete(key2)
          elsif key == "portvars"
            if value2.present?
              array = value2.split(/\s*,\s*/);

              if array.size>0
                array.each_with_index do |x,i|
                  match = x.match('^(!?)(\d+):(\d+)$')
                  unless match.nil?
                    if match[2].to_i<match[3].to_i
                      array[i] = x
                    elsif match[2].to_i==match[3].to_i
                      array[i] = match[1]+match[2]
                    else
                      array[i] = match[1]+match[3] +":" +match[2]
                    end
                  end
                end
                @role.override_attributes["redBorder"]["snort"][key][key2] = array.join(",")
              else
                @role.override_attributes["redBorder"]["snort"][key].delete(key2)
              end
            else
              @role.override_attributes["redBorder"]["snort"][key].delete(key2)
            end
          elsif key == "ipvars"
            if value2.present?
              array = value2.split(/\s*,\s*/);

              if array.size>0
                array.each_with_index do |x,i|
                  match = x.match('^(!?)([^/]+)/([^/]+)$')
                  array[i] = match[1] + NetAddr::CIDR.create(match[2]+'/'+match[3]).to_s unless match.nil?
                end
                @role.override_attributes["redBorder"]["snort"][key][key2] = array.join(",")
              else
                @role.override_attributes["redBorder"]["snort"][key].delete(key2)
              end
            else
              @role.override_attributes["redBorder"]["snort"][key].delete(key2)
            end

          else
            value2.present? ? @role.override_attributes["redBorder"]["snort"][key][key2] = to_boolean(value2) : @role.override_attributes["redBorder"]["snort"][key].delete(key2)
          end
        end
      else
        value.present? ? @role.override_attributes["redBorder"]["snort"][key] = value : @role.override_attributes["redBorder"]["snort"].delete(key)
      end
    end

    if params_role[:redBorder][:'syslog-ng'][:servers].nil? or params_role[:redBorder][:'syslog-ng'][:servers]==""
      @role.override_attributes["redBorder"]["syslog-ng"].delete("servers")
    else
      @role.override_attributes["redBorder"]["syslog-ng"]["servers"] = params_role[:redBorder][:'syslog-ng'][:servers].split(/\s*,\s*/)
    end
    @role.override_attributes["redBorder"]["syslog-ng"]["protocol"] = params_role[:redBorder][:'syslog-ng'][:protocol]
    if params_role[:redBorder][:smtp][:relayhost].nil? or params_role[:redBorder][:smtp][:relayhost]==""
      @role.override_attributes["redBorder"]["smtp"].delete("relayhost")
    else
      @role.override_attributes["redBorder"]["smtp"]["relayhost"] = params_role[:redBorder][:smtp][:relayhost]
    end

    if @sensor.update(params[:sensor])
      @role.override_attributes["redBorder"]["snort"]["initialized"] = true if (@sensor.domain and @sensor.virtual_sensor)
      
      if @role.save
        #debemos despertar chef-client
        @sensor.wakeup_chef
        redirect_to(edit_sensor_path, :notice => 'Sensor was successfully updated.')
      else
        redirect_to(edit_sensor_path, :notice => 'Was an error updating the sensor.')
      end
    else
      redirect_to(edit_sensor_path, :notice => 'Was an error updating the sensor.')
    end
  end

  # Method used when a sensor is has been dragged and dropped to another sensor.
  def update_parent
    parent_sensor = Sensor.get(params[:p_sid])
    if (@sensor.all_childs.include?(parent_sensor) or parent_sensor == @sensor.parent or parent_sensor.nil?)
      respond_to do |format|
        format.js { head :forbidden }
      end
    else
      @sensor.update(:parent_sid => params[:p_sid])
      @sensor.reload
      Delayed::Job.enqueue(Snorby::Jobs::CompilationJob.new(@sensor.sid, User.current_user.id, "Drag and Drop Compilation", true, false, false),
                           :priority => 1,
                           :run_at => Time.now + 5.seconds)
      hierarchy = Sensor.root.hierarchy(10)
      @sensors = []
      @sensors = hierarchy.flatten.compact.select{|s| can? :read, s} unless hierarchy.nil?

      respond_to :js
    end
  end

  def new_trap
    render :layout => false
  end

  def add_trap
    @role = @sensor.chef_role
    trap_server = {"ip" => params[:trap][:ip], "community" => params[:trap][:community]}

    @found = false

    @role.override_attributes["redBorder"]["snmp"]["trap_servers"].each do |server|
      @found = (server["ip"] == params[:trap][:ip])
      break if @found
    end

    if !@found
      @role.override_attributes["redBorder"]["snmp"]["trap_servers"] << trap_server
      @role.save
    end

    respond_to :js
  end

  def delete_trap
    @role = @sensor.chef_role
    @role.override_attributes["redBorder"]["snmp"]["trap_servers"].delete_at(params[:trap_index].to_i)
    @role.save
    respond_to :js
  end
  
  def bypass
    @sensor = Sensor.get(params[:sensor_id])
    
    if cannot?(:manage, @sensor) or !/bpbr\d/.match(params[:segment]) or !["on", "off"].include?(params[:mode])
      flash[:error] = "Access denied"
      render js: %(window.location.pathname='#{sensor_path(@sensor)}')
      return
    end
    
    @sensor.execute("sudo /bin/rb_bypass.sh -b #{params[:segment]} -s #{params[:mode]} -r")
    result = (params[:mode] == 'on')
    count = 0
    while @sensor.chef_node[:redBorder][:segments][params[:segment].to_sym][:bypass] != result and count < 50
      sleep(0.5)
      count += 1
    end
    @segment = params[:segment]
    @node = @sensor.chef_node
    respond_to :js
  end

  def search
    @total ||= Event.count

    if params[:q]

      sensors = Sensor.all(:fields => [:sid, :name], :virtual_sensor => true, :name.like => "%#{params[:q]}%")
      sensors.sort!{ |a,b| b.events_count <=> a.events_count }

      render :json => {
        :sensors => sensors,
        :total => @total
      }

    else
      render :json => { sensors: [] }
    end
  end

  private

    def create_virtual_sensors
      begin
        sensors1 = Sensor.all(:domain => false, :parent_sid => nil)
        sensors1.each do |sensor|
          if sensor.hostname.include? ':'
            match = /([^:]+):/.match(sensor.hostname)
            pname = match[1]
          else
            pname = sensor.hostname
          end
          p_sensor = Sensor.first(:name => pname, :hostname => pname, :domain => true, :virtual_sensor => true)
          if p_sensor.nil?
            p_sensor = Sensor.create(:name => pname, :hostname => pname, :domain => true, :parent => Sensor.root, :virtual_sensor => true, :dbversion => RuleDbversion.active, :compilation => RuleCompilation.first)
            node     = p_sensor.chef_node
            node.run_list("role[#{p_sensor.chef_name}]")
            node.save
          end

          sensor.update!(:parent => p_sensor, :dbversion_id => 1, :compilation_id => 1)
        end

        sensors2 = Sensor.all(:ipdir => nil, :virtual_sensor => true)
        sensors2.each do |sensor2|
          node = sensor2.chef_node
          sensor2.update!(:ipdir => node[:ipaddress])
        end

        Sensor.root.chef_role
      rescue
        #TODO. imprimir logs del error
        Sensor.repair_chef_db
        sensors1 = [1]   #para que tenga un valor y haga la redirección
      end

      if sensors1.present? || sensors2.present?
        Sensor.repair_chef_db
        # Needed to reload the object. Without that, index need to be reload twice to view the sensors created.
        redirect_to sensors_path
      end
    end

    def check_compilation_jobs
      Sensor.update!(:compiling => false) unless Snorby::Jobs.compilation_running?
    end

    def default_values
      @sensor = (Sensor.get(params[:sensor_id]) or Sensor.get(params[:id]))
      if @sensor.deleted
        redirect_to sensors_path
        flash[:error] = "The sensor will be deleted."
      end
      @role   = @sensor.chef_role unless @sensor.nil?
      @node   = @sensor.chef_node unless @sensor.nil?
    end

    def event_values (cache)
      @src_metrics = cache.src_metrics
      @dst_metrics = cache.dst_metrics

      @tcp  = cache.protocol_count(:tcp, @range.to_sym)
      @udp  = cache.protocol_count(:udp, @range.to_sym)
      @icmp = cache.protocol_count(:icmp, @range.to_sym)

      @signature_metrics = cache.signature_metrics

      @high   = cache.severity_count(:high, @range.to_sym)
      @medium = cache.severity_count(:medium, @range.to_sym)
      @low    = cache.severity_count(:low, @range.to_sym)

      @event_count = @high.sum + @medium.sum + @low.sum

      @sensor_metrics = cache.sensor_metrics(@range.to_sym)
    end

    def traps_values
      @trap_count = @sensor.traps(:timestamp.gte => Time.now.yesterday).size
    end

    def snmp_values
      @range  = 'last_24'
      @now    = Time.zone.now

      @snmp         = Snmp.last_24(@now.yesterday, @now).all(:snmp_type => 'snmp_statistics', :sensor => @sensor.virtual_sensors)
      @metrics      = @snmp.metrics

      @cpu_metric = @snmp.snmp_metrics("1.3.6.1.4.1.2021.11.11.0", @range.to_sym)
      @memory_metric = @snmp.snmp_metrics("1.3.6.1.4.1.39483.1.2.2.4.1.2.9.115.104.101.108.108.116.101.115.116.1", @range.to_sym)
      @load_metric = @snmp.snmp_metrics("1.3.6.1.4.1.2021.10.1.3.2", @range.to_sym)
      @hdd_metric = @snmp.snmp_metrics("1.3.6.1.4.1.2021.9.1.9.1", @range.to_sym)

      @high_snmp    = @snmp.severity_count(:high, @range.to_sym)
      @medium_snmp  = @snmp.severity_count(:medium, @range.to_sym)
      @low_snmp     = @snmp.severity_count(:low, @range.to_sym)

      @axis = Cache.count_hash(@range.to_sym).keys.collect {|x| "'#{x.split('-').last}'" }.join(',')
      
      @snmp_count = @high_snmp.sum + @medium_snmp.sum + @low_snmp.sum
    end

    def segments_values
      snmp_traffic = Snmp.last_3_hours(Time.now - 3.hours, Time.now).all(:snmp_type => 'snmp_traffic', :sensor => @sensor)
      @segments_metrics = snmp_traffic.traffic_metrics(:last_3_hours)
      if @segments_metrics.last
        #index = 0        
        #@axis = @segments_metrics.last[:range].map{|x| index += 1; index % 2 == 1 ? x : "' '"}.join(',')
        @axis = @segments_metrics.last[:range].join(',')
      end
    end

    def to_boolean(value)
      case value
      when "true"
        return true
      when {"mode" => "true"}
        return {"mode" => true}
      when "false"
        return false
      when {"mode" => "false"}
        return {"mode" => false}
      else
        return value
      end
    end

end
