class SettingsController < ApplicationController

  before_filter :require_administrative_privileges

  def index
    file = File.open("config/#{Snorby::CONFIG[:rsa_filename]}")
    @role = Sensor.chef_manager_role
    @rsa_content = ""
    file.each {|line|
      @rsa_content << line
    }
  end

  def create
    @params = params[:settings]
    @settings = Setting.all

    @settings.each do |setting|
      name = setting.name
      
      if @params.keys.include?(name)
        if @params[name].kind_of?(ActionDispatch::Http::UploadedFile)
          Setting.file(name, @params[name])
        else
          setting.update(:value => @params[name])
        end
      else
        setting.update(:value => nil) if setting.checkbox?
      end
    end

    @role = Sensor.chef_manager_role

    #Chef attributes
    @role.override_attributes["redBorder"]["smtp"]["relayhost"]   = params["role"]["redBorder"]["smtp"]["relayhost"]
    @role.override_attributes["redBorder"]["syslog-ng"]["servers"]  = params["role"]["redBorder"]["syslog-ng"]["servers"].split(/\s*,\s*/)
    @role.override_attributes["redBorder"]["syslog-ng"]["protocol"] = params["role"]["redBorder"]["syslog-ng"]["protocol"]
    @role.override_attributes["redBorder"]["ntp"]["servers"]      = params["role"]["redBorder"]["ntp"]["servers"].split(/\s*,\s*/)
    @role.save

    redirect_to settings_path, :notice => 'Settings Updated Successfully.'
  end

  def update

  end

  def recreate_rsa
    out=`[ -f /bin/rb_create_rsa.sh ] && /bin/rb_create_rsa.sh -f`

    if out.empty?
      redirect_to settings_path, :notice => "The RSA key hasn't been recreated"
    else
      redirect_to settings_path, :notice => 'The RSA key has been recreated successfully.'
    end
  end

  def start_worker
    Snorby::Worker.start unless Snorby::Worker.running?
    redirect_to jobs_path
  end

  def start_main
    Snorby::Jobs.main.destroy! if Snorby::Jobs.main?
    Delayed::Job.enqueue(Snorby::Jobs::Main.new(false), :priority => 1)
    redirect_to jobs_path
  end

  def start_sensor_cache
    Snorby::Jobs.sensor_cache.destroy! if Snorby::Jobs.sensor_cache?
    Delayed::Job.enqueue(Snorby::Jobs::SensorCacheJob.new(false), :priority => 5, :run_at => Time.now)
    redirect_to jobs_path
  end

  def start_daily_cache
    Snorby::Jobs.daily_cache.destroy! if Snorby::Jobs.daily_cache?
    Delayed::Job.enqueue(Snorby::Jobs::DailyCacheJob.new(false), :priority => 10, :run_at => Time.now.tomorrow.beginning_of_day)
    redirect_to jobs_path
  end
  
  def start_geoip_update
    Snorby::Jobs.geoip_update.destroy! if Snorby::Jobs.geoip_update?
    Delayed::Job.enqueue(Snorby::Jobs::GeoipUpdatedbJob.new(false), :priority => 25, :run_at => (Time.now + 2.minutes))
    redirect_to jobs_path
  end
  
  # Starts the Snmp Job like the others jobs.
  def start_snmp
    Snorby::Jobs.snmp.destroy! if Snorby::Jobs.snmp?
    Delayed::Job.enqueue(Snorby::Jobs::SnmpJob.new(false), :priority => 20)
    redirect_to jobs_path
  end

  def start_rule_update
    Snorby::Jobs.rule_update.destroy! if Snorby::Jobs.rule_update?
    Delayed::Job.enqueue(Snorby::Jobs::RuleUpdatedbJob.new(false), :priority => 15, :run_at => (Time.now + 2.minutes))
    redirect_to jobs_path
  end

  def restart_worker
    Snorby::Worker.restart if Snorby::Worker.running?
    redirect_to jobs_path
  end

  # Stops the worker.
  def stop_worker
    Snorby::Worker.stop if Snorby::Worker.running?
    redirect_to jobs_path
  end

  def new_trap
    render :layout => false
  end

  def add_trap
    @role = Sensor.chef_manager_role
    trap_server = {"ip" => params[:trap][:ip], "community" => params[:trap][:community]}

    if @role.override_attributes["redBorder"]["snmp"]["trap_servers"].nil?
      @role.override_attributes["redBorder"]["snmp"]["trap_servers"] = [] 
      @role.save
    end

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
    @role = Sensor.chef_manager_role
    @role.override_attributes["redBorder"]["snmp"]["trap_servers"].delete_at(params[:trap_index].to_i) unless @role.override_attributes["redBorder"]["snmp"]["trap_servers"].nil?
    @role.save
    respond_to :js
  end
end
