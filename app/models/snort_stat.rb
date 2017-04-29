class SnortStat
  
  include DataMapper::Resource

  
  property :id, Serial, :key => true, :index => true

  property :instance, Integer
  
  property :timestamp, DateTime
  
  property :value, Float
  
  belongs_to :sensor, :parent_key => :sid, :child_key => :sid
  
  belongs_to :snort_stat_name
  
  validates_uniqueness_of :timestamp, :scope => [:sid, :instance, :snort_stat_name_id]
  
  SORT = {
    :sensor_name  => "sensor",
    :instance     => "stat",
    :value        => "stat",
    :timestamp    => "stat",
    :name         => "snort_stat_name"
  }
  
  def pretty_time
    if Setting.utc?
      return "#{timestamp.utc.strftime('%l:%M %p')}" if Date.today.to_date == timestamp.to_date
      "#{timestamp.utc.strftime('%m/%d/%Y')}"
    else
      return "#{timestamp.strftime('%l:%M %p')}" if Date.today.to_date == timestamp.to_date
      "#{timestamp.strftime('%m/%d/%Y')}"
    end
  end
  
  #return a hash whose keys are the instances
  def self.get_value(host, oid)
    community = Snorby::CONFIG_SNMP[:community].nil? ? 'public' : Snorby::CONFIG_SNMP[:community]
    manager = SNMP::Manager.new(:Host => host, :community => community)
    response = manager.get(oid)
    
    values = response.varbind_list.first.value.split(";")
    
    hash_values = Hash.new
    
    values.each do |value| 
      value = value.split(":")
      
      if hash_values[value[0].to_i]
        hash_values[value[0].to_i][value[1]] = value[2]
      else  
        hash_values[value[0].to_i] = Hash[value[1], value[2]]
      end
      
    end
    
    hash_values

  end
  
  def self.sorty(params={})
    sort = params[:sort]
    direction = params[:direction]

    page = {
      :per_page => User.current_user.per_page_count
    }

    if SORT[sort].downcase == 'stat'
      page.merge!(:order => sort.send(direction))
    elsif SORT[sort].downcase == 'sensor'
      page.merge!(:order => [SnortStat.send(SORT[:name].to_sym).send(:name).send(direction), :timestamp.send(direction)],
                  :links => [SnortStat.relationships[SORT[:name].to_s].inverse])
    else
      page.merge!(:order => [SnortStat.send(SORT[sort].to_sym).send(sort).send(direction), :timestamp.send(direction)],
                  :links => [SnortStat.relationships[SORT[sort].to_s].inverse])
    end
    
    ability = Ability.new(User.current_user)

    if params.has_key?(:sensor_id)
      sensor = Sensor.get!(params[:sensor_id])
      virtual_sensors = sensor.virtual_sensors.select{|s| ability.can?(:read, s)}

      page.merge!(:sid => virtual_sensors.map{|s| s.sid})
    end

    if params.has_key?(:search)

      params[:search].delete_if{|key, value| value.blank?}

      if params[:search][:sid]
        sensor = Sensor.get!(params[:search][:sid])
        virtual_sensors = sensor.virtual_sensors.select{|s| ability.can?(:read, s)}
        params[:search][:sid] = virtual_sensors.map{|s| s.sid}
      else
        sensor = Sensor.root
        virtual_sensors = sensor.virtual_sensors.select{|s| ability.can?(:read, s)}
        params[:search][:sid] = virtual_sensors.map{|s| s.sid}
      end

    else
    
      params[:search] = Hash.new
      sensor = Sensor.root
      virtual_sensors = sensor.virtual_sensors.select{|s| ability.can?(:read, s)}
      params[:search][:sid] = virtual_sensors.map{|s| s.sid}
      
    end

    params[:search][:sid] = 0 if params[:search][:sid].blank?

    page.merge!(params[:search])

    page.merge!(:"snort_stat_name.enable" => true)

    page(params[:page].to_i, page)
  end
  
  def self.last_3_hours(first=nil,last=nil)
    current = Time.now
    end_time = last ? last : current
    start_time = first ? first : current - 3.hours

    all(:timestamp.gte => start_time.utc, :timestamp.lte => end_time.utc)
  end

  def self.last_24(first=nil,last=nil)
    current = Time.zone.now
    end_time = last ? last : current
    start_time = first ? first : current.yesterday

    all(:timestamp.gte => start_time.utc, :timestamp.lte => end_time.utc)
  end

  def self.today
    all(:timestamp.gte => Time.now.beginning_of_day, :timestamp.lte => Time.now.end_of_day)
  end
  
  def self.yesterday
    all(:timestamp.gte => Time.now.yesterday.beginning_of_day, :timestamp.lte => Time.now.yesterday.end_of_day)
  end
  
  def self.this_week
    all(:timestamp.gte => Time.now.beginning_of_week, :timestamp.lte => Time.now.end_of_week)
  end
  
  def self.last_week
    all(:timestamp.gte => Time.now - 1.week, :timestamp.lte => Time.now)
  end
  
  
  def self.this_month
    all(:timestamp.gte => Time.now.beginning_of_month, :timestamp.lte => Time.now.end_of_month)  
  end
  
  def self.last_month
    all(:timestamp.gte => Time.now - 1.months, :timestamp.lte => Time.now)  
  end
    
  def self.this_quarter
    all(:timestamp.gte => Time.now.beginning_of_quarter, :timestamp.lte => Time.now.end_of_quarter)  
  end
  
  def self.last_quarter
    all(:timestamp.gte => Time.now - 3.months, :timestamp.lte => Time.now)
  end
  
  def self.this_year
    all(:timestamp.gte => Time.now.beginning_of_year, :timestamp.lte => Time.now.end_of_year)  
  end

  def self.last_year
    all(:timestamp.gte => Time.now - 1.year, :timestamp.lte => Time.now)
  end
  
  def self.metrics(type=:week)
    metrics_array = []
    SnortStatName.all(:enable => true).each{|s| metrics_array << self.snort_stat_metrics(s, type)}
    metrics_array
  end
  
  def self.metrics_by_sensor(type=:week)
    metrics_array = []
    SnortStatName.all(:enable => true).each{|s| metrics_array << self.snort_stat_metrics_by_sensor(s, type)}
    metrics_array
  end
  
  def self.snort_stat_metrics_by_sensor(snort_stat_name, type)
    metrics = {:snort_stat_name => snort_stat_name, :data => []}

    self.map(&:instance).uniq.sort.each do |instance|
      count = []
      time_range = []

      stats = snort_stat_for_type(self.all(:snort_stat_name => snort_stat_name), type, false, instance)

      if stats.empty?

        range_for_type(type) do |i|
          time_range << "'#{i}'"
          count << 0
        end

      else

        range_for_type(type) do |i|
          time_range << "'#{i}'"

          if stats.has_key?(i)
            count << (stats[i].map{|d| d.value.to_f}.sum / stats[i].count).round(2)
          else
            count << nil
          end

        end

      end

      metrics[:data] << { :name => "Instance #{instance}", :data => count, :range => time_range }

    end

    metrics
    
  end
  
  def self.snort_stat_metrics(snort_stat_name, type)
    metrics = {:snort_stat_name => snort_stat_name, :data => []}

    self.all.sensors.each do |sensor|
      count = []
      time_range = []

      stats = snort_stat_for_type(self.all(:snort_stat_name => snort_stat_name), type, sensor)

      if stats.empty?

        range_for_type(type) do |i|
          time_range << "'#{i}'"
          count << 0
        end

      else

        range_for_type(type) do |i|
          time_range << "'#{i}'"

          if stats.has_key?(i)
            count << (stats[i].map{|d| d.value.to_f}.sum / stats[i].count).round(2)
          else
            count << nil
          end

        end

      end

      metrics[:data] << { :name => sensor.sensor_name, :data => count, :range => time_range }

    end

    metrics
    
  end
  
  def self.snort_stat_for_type(collection, type=:week, sensor=false, instance=false)
    if sensor
      search = {:sid => sensor.sid}
    elsif instance
      search = {:instance => instance}
    end
    
    case type.to_sym
    when :last_3_hours
      return collection.group_by { |x| "#{x.timestamp.in_time_zone.hour}:#{x.timestamp.in_time_zone.min / 10}0" } unless (sensor or instance)
      return collection.all(search).group_by { |x| "#{x.timestamp.in_time_zone.hour}:#{x.timestamp.in_time_zone.min / 10}0" }
      
    when :last_24
      return collection.group_by { |x| "#{x.timestamp.in_time_zone.hour}" } unless (sensor or instance)
      return collection.all(search).group_by { |x| "#{x.timestamp.in_time_zone.hour}" }
    when :week, :last_week
      return collection.group_by { |x| x.timestamp.day } unless (sensor or instance)
      return collection.all(search).group_by { |x| x.timestamp.day }
    when :month, :last_month
      return collection.group_by { |x| x.timestamp.day } unless (sensor or instance)
      return collection.all(search).group_by { |x| x.timestamp.day }
    when :year, :quarter
      return collection.group_by { |x| x.timestamp.month } unless (sensor or instance)
      return collection.all(search).group_by { |x| x.timestamp.month }
    when :last_quarter
      return collection.group_by { |x| "#{x.timestamp.year}-#{x.timestamp.month}-#{x.timestamp.day}" } unless sensor
      return collection.all(:sid => sensor.sid).group_by { |x| "#{x.timestamp.year}-#{x.timestamp.month}-#{x.timestamp.day}" }
    when :last_year
      return collection.group_by { |x| "#{x.timestamp.year}-#{x.timestamp.month}" } unless sensor
      return collection.all(:sid => sensor.sid).group_by { |x| "#{x.timestamp.year}-#{x.timestamp.month}" }
    else
      return collection.group_by { |x| x.timestamp.hour } unless (sensor or instance)
      return collection.all(search).group_by { |x| x.timestamp.hour }
    end
  end
  
  def self.range_for_type(type=:week, &block)

    case type.to_sym
      
    when :last_3_hours  
      
      Range.new((Time.now - 3.hours).to_i, Time.now.to_i).step(10.minutes).each do |i|
        block.call("#{Time.zone.at(i).hour}:#{Time.zone.at(i).min / 10}0") if block
      end

    when :last_24

      Range.new((Time.now.yesterday + 1.hour).to_i, Time.now.to_i).step(1.hour).each do |i|
        block.call("#{Time.zone.at(i).hour}") if block
      end

    when :week

      ((Time.now.beginning_of_week.to_date)..(Time.now.end_of_week.to_date)).to_a.each do |i|
        block.call(i.day) if block
      end

    when :last_week

      (((Time.now - 1.week).to_date)..((Time.now).to_date)).to_a.each do |i|
        block.call(i.day) if block
      end

    when :month

      ((Time.now.beginning_of_month.to_date)..(Time.now.end_of_month.to_date)).to_a.each do |i|
        block.call(i.day) if block
      end

    when :last_month

      (((Time.now - 1.month).to_date)..((Time.now).to_date)).to_a.each do |i|
        block.call(i.day) if block
      end

    when :quarter

      ((Time.now.beginning_of_quarter.month)..(Time.now.end_of_quarter.month)).to_a.each do |i|
        block.call(i) if block
      end

    when :last_quarter

      ((Time.now - 3.months).to_date..Time.now.to_date).to_a.each do |i|
        block.call("#{i.year}-#{i.month}-#{i.day}") if block
      end

    when :year

      Time.now.beginning_of_year.month.upto(Time.now.end_of_year.month) do |i|
        block.call(i) if block
      end

    when :last_year

      year_month = ((Time.now - 1.year).to_date..Time.now.to_date).to_a.map{|x| "#{x.year}-#{x.month}"}.uniq

      year_month.each do |i|
        block.call(i) if block
      end

    else

      ((Time.now.beginning_of_day.hour)..(Time.now.end_of_day.hour)).to_a.each do |i|
        block.call(i) if block
      end

    end

  end
  
end
