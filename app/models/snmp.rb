class Snmp

  include DataMapper::Resource
  
  # Included for the truncate helper method.
  extend ActionView::Helpers::TextHelper

  SNMP_TYPE = ['snmp_statistics', 'snmp_traffic']
  AGGREGATED_COLUMNS = {
    :CPU => "CPU",
    :MEMORY => "Memory",
    :LOAD => "Load",
    :HDD => "HDD",
    :SEVERITIES => "Severities"
  }

  property :id, Serial, :key => true, :index => true

  property :sid, Integer

  property :timestamp, DateTime

  property :snmp_key, Text
  
  property :value, Float

  property :snmp_type, String

  belongs_to :sensor, :parent_key => :sid, :child_key => :sid, :required => true
    
    SORT = {
      :sid => 'snmp', 
      :timestamp => 'snmp'
    }

  def pretty_time
    return "#{timestamp.in_time_zone.strftime('%l:%M %p')}" if Date.today.to_date == timestamp.to_date
    "#{timestamp.in_time_zone.strftime('%m/%d/%Y')}"
  end

  def self.get_value(host, snmp_key, snmp_key_ref=nil, mult=nil, inverse=nil)
    community = Snorby::CONFIG_SNMP[:community].nil? ? 'public' : Snorby::CONFIG_SNMP[:community]
    manager = SNMP::Manager.new(:Host => host, :community => community)
    response = manager.get(snmp_key)
    response_ref = manager.get(snmp_key_ref) unless snmp_key_ref.nil?

    mult = mult or 1

    if response_ref.nil?
      value = response.varbind_list.first.value
    elsif inverse
      value = (response_ref.varbind_list.first.value.to_f - response.varbind_list.first.value.to_f) / response_ref.varbind_list.first.value.to_f * mult.to_f
    else
      value = response.varbind_list.first.value.to_f / response_ref.varbind_list.first.value.to_f * mult.to_f
    end
    
    value
  end

  def self.sorty(params={})
    sort = params[:sort]
    direction = params[:direction]

    page = {
      :per_page => User.current_user.per_page_count
    }

    if SORT[sort].downcase == 'snmp'
      page.merge!(:order => sort.send(direction))
    else
      page.merge!(
        :order => [Snmp.send(SORT[sort].to_sym).send(sort).send(direction), 
                   :timestamp.send(direction)],
        :links => [Snmp.relationships[SORT[sort].to_s].inverse]
      )
    end
    
    ability = Ability.new(User.current_user)
    
    if params.has_key?(:search)

      params[:search].delete_if{|key, value| value.blank?}

      if params[:search].has_key?(:sid)
        
        sensor = Sensor.get(params[:search][:sid])
        params[:search][:sid] = []
        sensor.virtual_sensors.select{|s| ability.can?(:read, s)}.each{|x| params[:search][:sid] << x.sid}
        params[:search][:sid] = 0 if params[:search][:sid] and params[:search][:sid].blank?
      
      elsif !params[:search].has_key?(:sid) and !User.current_user.admin
        
        params[:search][:sid] = []
        Sensor.root.virtual_sensors.select{|s| ability.can?(:read, s)}.each{|x| params[:search][:sid] << x.sid}
        params[:search][:sid] = 0 if params[:search][:sid] and params[:search][:sid].blank?
        
      end
      
      page.merge!(search(params[:search]))
      
    elsif !params.has_key?(:search) and !User.current_user.admin
      
      params[:search] = Hash.new
      params[:search][:sid] = []
      Sensor.root.virtual_sensors.select{|s| ability.can?(:read, s)}.each{|x| params[:search][:sid] << x.sid}
      params[:search][:sid] = 0 if params[:search][:sid].blank?
      page.merge!(search(params[:search]))
      
    end

    page(params[:page].to_i, page)
    
  end
  
  def self.last_3_hours(first=nil,last=nil)
    current = Time.zone.now
    end_time = last ? last : current
    start_time = first ? first : current - 3.hours

    all(:timestamp.gte => start_time.utc, :timestamp.lte => end_time.utc)
  end

  def self.last_24(first=nil,last=nil)
    current = Time.zone.now
    end_time = last ? last : current
    start_time = first ? first : current.yesterday

    all(:timestamp.gte => start_time, :timestamp.lte => end_time)
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

  def self.metrics
    metrics_array = []
    Snorby::CONFIG_SNMP[:oids].each_key{|o| metrics_array << self.tops(o, 5)}
    metrics_array
  end

  def self.tops(snmp_key, number=5)
    sensors = Hash.new
    self.all(:snmp_key => snmp_key).group_by{|x| x.sid}.each{|k, v| sensors[k] = v.map{|x| x.value}.inject(:+).to_f / v.size unless k.nil? }
    sensors.sort{|a, b| b[1] <=> a[1] }.first(number)
  end
  
  def self.snmp_metrics(snmp_key, type)
    metrics = []

    if self.all.sensors.count > 5
      sensors = Hash.new
      self.all(:snmp_key => snmp_key).group_by{|x| x.sensor}.each{|k, v| sensors[k] = v.map{|x| x.value}.inject(:+).to_f / v.size }
      sensors = sensors.sort{|a, b| b[1] <=> a[1] }.first(5).map(&:first)
    else
      sensors = self.all.sensors
    end

    sensors.each do |sensor|
      count = []
      time_range = []
      snmp = snmp_for_type(self.all(:snmp_key => snmp_key), type, sensor)
      if snmp.empty?
        range_for_type(type) do |i|
          time_range << "'#{i}'"
          count << 0
        end
      else
        range_for_type(type) do |i|
          time_range << "'#{i}'"
          if snmp.has_key?(i)
            count << (snmp[i].map{|d| d.value.to_f}.sum / snmp[i].count).round(2)
          else
            count << nil
          end
        end
      end
      metrics << { :name => sensor.sensor_name, :data => count, :range => time_range }
    end
    metrics
  end

  # the method is only for one sensor
  def self.traffic_metrics(type=:last_24)
    metrics = []

    self.map(&:snmp_key).uniq.each do |bpbr|

      result = []
      time_range = []

      snmp = snmp_for_type(self.all(:snmp_key => bpbr), type)

      if snmp.empty?

        range_for_type(type) do |i|
          time_range << "'#{i}'"
          result << 0
        end

      else

        range_for_type(type) do |i|
          time_range << "'#{i}'"

          if snmp.has_key?(i) and snmp[i].count > 1
            mbps = (snmp[i].last.value - snmp[i].first.value) / (snmp[i].last.timestamp.to_i - snmp[i].first.timestamp.to_i)
            result << (mbps < 0 ? 0 : mbps.round(2))
          else
            result << 0
          end
        end

      end

      metrics << { :name => bpbr, :data => result, :range => time_range }

    end
  
    metrics

  end
  
  def self.snmp_for_type(collection, type=:week, sensor=false)
    case type.to_sym
    when :last_3_hours
      return collection.group_by { |x| "#{x.timestamp.in_time_zone.strftime('%H').to_i}:#{x.timestamp.in_time_zone.strftime('%M').to_i / 10}0" } unless sensor
      return collection.all(:sid => sensor.sid).group_by { |x| "#{x.timestamp.in_time_zone.strftime('%H').to_i}:#{x.timestamp.in_time_zone.strftime('%M').to_i / 10}0" }
    when :last_24
      return collection.group_by { |x| "#{x.timestamp.in_time_zone.day}-#{x.timestamp.in_time_zone.hour}" } unless sensor
      return collection.all(:sid => sensor.sid).group_by { |x| "#{x.timestamp.in_time_zone.day}-#{x.timestamp.in_time_zone.hour}" }
    when :week, :last_week
      return collection.group_by { |x| x.timestamp.day } unless sensor
      return collection.all(:sid => sensor.sid).group_by { |x| x.timestamp.day }
    when :month, :last_month
      return collection.group_by { |x| x.timestamp.day } unless sensor
      return collection.all(:sid => sensor.sid).group_by { |x| x.timestamp.day }
    when :year, :quarter
      return collection.group_by { |x| x.timestamp.month } unless sensor
      return collection.all(:sid => sensor.sid).group_by { |x| x.timestamp.month }
    when :last_quarter
      return collection.group_by { |x| "#{x.timestamp.year}-#{x.timestamp.month}-#{x.timestamp.day}" } unless sensor
      return collection.all(:sid => sensor.sid).group_by { |x| "#{x.timestamp.year}-#{x.timestamp.month}-#{x.timestamp.day}" }
    when :last_quarter_severity
      return collection.group_by { |x| "#{x.timestamp.strftime('%V')}" } unless sensor
      return collection.all(:sid => sensor.sid).group_by { |x| "#{x.timestamp.strftime('%V')}" }
    when :last_year
      return collection.group_by { |x| "#{x.timestamp.year}-#{x.timestamp.month}" } unless sensor
      return collection.all(:sid => sensor.sid).group_by { |x| "#{x.timestamp.year}-#{x.timestamp.month}" }
    else
      return collection.group_by { |x| x.timestamp.day } unless sensor
      return collection.all(:sid => sensor.sid).group_by { |x| x.timestamp.day }
    end
  end
  
  def self.range_for_type(type=:week, &block)

    case type.to_sym
      
    when :last_3_hours  
      
      Range.new((Time.now - 3.hours).to_i, Time.now.to_i).step(10.minutes).each do |i|
        block.call("#{Time.zone.at(i).hour}:#{Time.zone.at(i).min / 10}0") if block
      end

    when :last_24

      Range.new((Time.now.yesterday).to_i, Time.now.to_i).step(1.hour).each do |i|
        block.call("#{Time.zone.at(i).day}-#{Time.zone.at(i).hour}") if block
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

    when :last_quarter_severity

      ((Time.now - 3.months).to_date..Time.now.to_date).to_a.each do |i|
        block.call("#{i.strftime('%V')}") if block
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

  def self.severity_count(severity, type=nil, bar=false)
    
    count = {}
    
    type = :last_quarter_severity if type == :last_quarter and bar

    @snmp = snmp_for_type(self.all(:snmp_key => Snorby::CONFIG_SNMP[:oids].keys), type)

    level_high = Snorby::CONFIG_SNMP[:level_high].to_f
    level_medium = Snorby::CONFIG_SNMP[:level_medium].to_f

    case severity.to_sym

    when :high
      range_for_type(type) do |i|
        if @snmp.has_key?(i)
          count["#{i}"] = @snmp[i].select{|v| v.value.to_f >= level_high}.count
        else
          count["#{i}"] = 0
        end
      end

    when :medium
      range_for_type(type) do |i|
        if @snmp.has_key?(i)
          count["#{i}"] = @snmp[i].select{|v| v.value.to_f < level_high and v.value.to_f >= level_medium}.count
        else
          count["#{i}"] = 0
        end
      end
      
    when :low
      range_for_type(type) do |i|
        if @snmp.has_key?(i)
          count["#{i}"] = @snmp[i].select{|v| v.value.to_f < level_medium}.count
        else
          count["#{i}"] = 0
        end
      end
      
    end

    count.values

  end
  
  def self.search(params)
    
    @search = {}

    @search.merge!({:sid => params[:sid]}) unless params[:sid].blank?
    
    @search.merge!({:snmp_type => params[:snmp_type]}) unless params[:snmp_type].blank?

    @search.merge!({:snmp_key => params[:snmp_key]}) unless params[:snmp_key].blank?

    # Severity rating is taken from snmp_config 
    unless params[:severity].blank?
      if params[:severity].to_i == 1
        @search.merge!({:value.gte => Snorby::CONFIG_SNMP[:level_high].to_f})
      elsif params[:severity].to_i == 2
        @search.merge!({:value.gte => Snorby::CONFIG_SNMP[:level_medium].to_f, :value.lt => Snorby::CONFIG_SNMP[:level_high].to_f})
      else
        @search.merge!({:value.lt => Snorby::CONFIG_SNMP[:level_medium].to_f})
      end
    end
  
    # Timestamp
    if params[:timestamp].blank?

      unless params[:time_start].blank? || params[:time_end].blank?
        @search.merge!({
          :conditions => ['timestamp >= ? AND timestamp <= ?',
            Time.at(params[:time_start].to_i),
            Time.at(params[:time_end].to_i)
        ]})
      end

    else

      if params[:timestamp] =~ /\s\-\s/
        start_time, end_time = params[:timestamp].split(' - ')
        @search.merge!({:conditions => ['timestamp >= ? AND timestamp <= ?', 
                       Chronic.parse(start_time).beginning_of_day, 
                       Chronic.parse(end_time).end_of_day]})
      else
        @search.merge!({:conditions => ['timestamp >= ? AND timestamp <= ?', 
                       Chronic.parse(params[:timestamp]).beginning_of_day, 
                       Chronic.parse(params[:timestamp]).end_of_day]})
      end

    end
  
    @search

  rescue NetAddr::ValidationError => e
    {}
  rescue ArgumentError => e
    {}
  
  end

  def self.oids
    Snmp.all(:fields => [:snmp_key], :unique => true, :snmp_type => 'snmp_statistics').map{|s| s.snmp_key}
  end

  def self.count_hash(type=nil)
    count = {}
    time_end =  Time.zone.now.to_i

    case type
    when :last_3_hours
      time_start = Time.zone.now.to_i - 3.hours
      Range.new(time_start, time_end).step(10.minutes) do |seconds_since_epoch|
        time = Time.zone.at(seconds_since_epoch)
        key = "#{time.hour}:#{time.min}"
        count[key] = 0
      end
    when :last_24
      time_start = Time.zone.now.yesterday.to_i
      Range.new(time_start, time_end).step(1.hour) do |seconds_since_epoch|
        time = Time.zone.at(seconds_since_epoch)
        key = "#{time.day}-#{time.hour}"
        count[key] = 0
      end
    when :today
      time_start = Time.zone.now.beginning_of_day.to_i
      Range.new(time_start, time_end).step(1.hour) do |seconds_since_epoch|
        time = Time.zone.at(seconds_since_epoch)
        key = "#{time.day}-#{time.hour}"
        count[key] = 0
      end
    when :yesterday
      time_end   = (Time.zone.now-1.day).end_of_day.to_i
      time_start = (Time.zone.now-1.day).beginning_of_day.to_i
      Range.new(time_start, time_end).step(1.hour) do |seconds_since_epoch|
        time = Time.zone.at(seconds_since_epoch)
        key = "#{time.day}-#{time.hour}"
        count[key] = 0
      end
    when :before_1_yesterday
      time_end   = (Time.zone.now-2.day).end_of_day.to_i
      time_start = (Time.zone.now-2.day).beginning_of_day.to_i
      Range.new(time_start, time_end).step(1.hour) do |seconds_since_epoch|
        time = Time.zone.at(seconds_since_epoch)
        key = "#{time.day}-#{time.hour}"
        count[key] = 0
      end
    when :before_2_yesterday
      time_end   = (Time.zone.now-3.day).end_of_day.to_i
      time_start = (Time.zone.now-3.day).beginning_of_day.to_i
      Range.new(time_start, time_end).step(1.hour) do |seconds_since_epoch|
        time = Time.zone.at(seconds_since_epoch)
        key = "#{time.day}-#{time.hour}"
        count[key] = 0
      end
    when :before_3_yesterday
      time_end   = (Time.zone.now-4.day).end_of_day.to_i
      time_start = (Time.zone.now-4.day).beginning_of_day.to_i
      Range.new(time_start, time_end).step(1.hour) do |seconds_since_epoch|
        time = Time.zone.at(seconds_since_epoch)
        key = "#{time.day}-#{time.hour}"
        count[key] = 0
      end
    when :before_4_yesterday
      time_end   = (Time.zone.now-5.day).end_of_day.to_i
      time_start = (Time.zone.now-5.day).beginning_of_day.to_i
      Range.new(time_start, time_end).step(1.hour) do |seconds_since_epoch|
        time = Time.zone.at(seconds_since_epoch)
        key = "#{time.day}-#{time.hour}"
        count[key] = 0
      end
    when :last_week
      time_start = Time.zone.now.to_i - 1.week
      Range.new(time_start, time_end).step(1.day) do |seconds_since_epoch|
        time = Time.zone.at(seconds_since_epoch)
        key = "#{time.month}-#{time.day}"
        count[key] = 0
      end
    when :last_month
      time_start = (Time.zone.now - 1.month).to_i
      Range.new(time_start, time_end).step(1.day) do |seconds_since_epoch|
        time = Time.zone.at(seconds_since_epoch)
        key = "#{time.month}-#{time.day}"
        count[key] = 0
      end
    when :last_quarter
      time_start = (Time.zone.now - 3.months).to_i
      Range.new(time_start, time_end).step(1.day) do |seconds_since_epoch|
        time = Time.zone.at(seconds_since_epoch)
        key = "#{time.year}-#{time.month}-#{time.day}"
        count[key] = 0
      end
    when :last_year
      time_end = Date.today
      time_start = time_end - 1.year

      count[time_start.strftime("%Y-%-m")] = 0

      while time_start < time_end
        time_start >>= 1
        count[time_start.strftime("%Y-%-m")] = 0       
      end

    end
    count
  end

end
