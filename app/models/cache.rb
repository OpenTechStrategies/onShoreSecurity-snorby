class Cache 

  include DataMapper::Resource

  property :id, Serial
  property :sid, Integer
  property :cid, Integer
  property :ran_at, DateTime
  property :event_count, Integer, :default => 0
  property :tcp_count, Integer, :default => 0
  property :udp_count, Integer, :default => 0
  property :icmp_count, Integer, :default => 0
  property :severity_metrics, Object
  property :signature_metrics, Object
  property :src_ips, Object
  property :dst_ips, Object

  # Define created_at and updated_at timestamps
  timestamps :at

  belongs_to :sensor, :parent_key => :sid, :child_key => :sid

  has 1, :event, :parent_key => [ :sid, :cid ], :child_key => [ :sid, :cid ]

  def self.yesterday
    all(:ran_at.gte => Time.now.yesterday.beginning_of_day.utc, :ran_at.lte => Time.now.yesterday.end_of_day.utc)
  end

  def self.before_1_yesterday
    all(:ran_at.gte => (Time.now - 2.days).beginning_of_day.utc, :ran_at.lte => (Time.now - 2.days).end_of_day.utc)
  end

  def self.before_2_yesterday
    all(:ran_at.gte => (Time.now - 3.days).beginning_of_day.utc, :ran_at.lte => (Time.now - 3.days).end_of_day.utc)
  end

  def self.before_3_yesterday
    all(:ran_at.gte => (Time.now - 4.days).beginning_of_day.utc, :ran_at.lte => (Time.now - 4.days).end_of_day.utc)
  end

  def self.before_4_yesterday
    all(:ran_at.gte => (Time.now - 5.days).beginning_of_day.utc, :ran_at.lte => (Time.now - 5.days).end_of_day.utc)
  end

  def self.today
    all(:ran_at.gte => Time.now.beginning_of_day.utc, :ran_at.lte => Time.now.end_of_day.utc)
  end

  def self.last_24(first=nil,last=nil)
    current    = Time.now
    end_time   = last ? last : current
    start_time = first ? first : current.yesterday

    all(:ran_at.gte => start_time, :ran_at.lt => end_time)
  end
  
  def self.cache_time
    if (time = get_last)
      return time.updated_at
    else
      Time.now 
    end
  end

  def self.protocol_count(protocol, type=nil)
    count = count_hash(type)
    
    @cache = cache_for_type(self, :hour)

    case protocol.to_sym
    when :tcp
      @cache.each do |hour, data|
        count[hour] = data.map(&:tcp_count).sum
      end
    when :udp
      @cache.each do |hour, data|
        count[hour] = data.map(&:udp_count).sum
      end
    when :icmp
      @cache.each do |hour, data|
        count[hour] = data.map(&:icmp_count).sum
      end
    end

    count.values
  end

  def self.severity_count(severity, type=nil, b=false)
    count = count_hash(type)   
    
    @cache = cache_for_type(self, :hour)

    case severity.to_sym
    when :high
      @cache.each do |hour, data|
        high_count = 0
        data.map(&:severity_metrics).each { |x| high_count += (x.kind_of?(Hash) ? (x.has_key?(1) ? x[1] : 0) : 0) }
        count[hour] = high_count
      end
    when :medium
      @cache.each do |hour, data|
        medium_count = 0
        data.map(&:severity_metrics).each { |x| medium_count += (x.kind_of?(Hash) ? (x.has_key?(2) ? x[2] : 0) : 0) }
        count[hour] = medium_count
      end
    when :low
      @cache.each do |hour, data|
        low_count = 0
        data.map(&:severity_metrics).each { |x| low_count += ( x.kind_of?(Hash) ? (x.has_key?(3) ? x[3] : 0) : 0) }
        count[hour] = low_count
      end
    end

    count.values
  end

  def self.get_last
    first(:order => [:updated_at.desc])
  end

  def self.sensor_metrics(type=nil)
    metrics = []
    sensors = {}

    self.aggregate(:sid, :event_count.sum).select{|c| Sensor.get(c[0]) and !Sensor.get(c[0]).domain}.group_by{|c| Sensor.get(c[0]).parent}.each_pair do |k, v|
      sensors[k] = v.map{|a| a[1]}.sum
    end

    sensors = sensors.sort{|s1, s2| s2[1] <=> s1[1]}.map{|s| s[0]}.first(10)

    sensors.each do |sensor|
      count = count_hash(type)

      unless sensor.nil? 
        blah = self.all(:sid => sensor.real_sensors.map{|s| s.sid}).group_by { |x| x.ran_at.strftime("%e-%H") }
      
        blah.each do |hour, data|
          count[hour] = data.map(&:event_count).sum
        end

        #unless count.values.sum == 0
        metrics << {
          :sid => sensor.sid, 
          :name => sensor.sensor_name,
          :data => count.values
        }
      end
    end
    metrics
  end

  def self.src_metrics(limit=20)
    @metrics = {}
    @top = []
    @cache = self.map(&:src_ips).compact
    count = 0

    @cache.each do |ip_hash|

      ip_hash.each do |ip, count|
        if @metrics.has_key?(ip)
          @metrics[ip] += count
        else
          @metrics.merge!({ip => count})
        end
      end
    end

    @metrics.sort{ |a,b| -1*(a[1]<=>b[1]) }.each do |data|
      break if count >= limit
      @top << data
      count += 1
    end
    
    @top
  end

  def self.dst_metrics(limit=20)
    @metrics = {}
    @top = []
    @cache = self.map(&:dst_ips).compact
    count = 0

    @cache.each do |ip_hash|

      ip_hash.each do |ip, count|
        if @metrics.has_key?(ip)
          @metrics[ip] += count
        else
          @metrics.merge!({ip => count})
        end
      end
    end

    @metrics.sort{ |a,b| -1*(a[1]<=>b[1]) }.each do |data|
      break if count >= limit
      @top << data
      count += 1
    end
    
    @top
  end

  def self.signature_metrics(limit=20)
    @metrics = {}
    @top = []
    @cache = self
    count = 0

    @cache.map(&:signature_metrics).each do |data|
      next unless data

      data.each do |id, value|
        if @metrics.has_key?(id)
          temp_count = @metrics[id]
          @metrics.merge!({id => temp_count + value})
        else
          @metrics.merge!({id => value})
        end
      end

    end

    @metrics.sort{ |a,b| -1*(a[1]<=>b[1]) }.each do |data|
      break if count >= limit
      @top << data
      count += 1
    end
    
    @top
  end

  def self.count_hash(type=nil)
    count = {}
    time_end =  Time.now.to_i

    case type
    when :last_3_hours
      time_start = Time.now.to_i - 3.hours
      Range.new(time_start, time_end).step(10.minutes) do |seconds_since_epoch|
        time = Time.at(seconds_since_epoch)
        key = "#{time.hour}:#{time.min}"
        count[key] = 0
      end
    when :last_24
      time_start = Time.now.yesterday.to_i
      Range.new(time_start, time_end).step(1.hour) do |seconds_since_epoch|
        time = Time.at(seconds_since_epoch)
        key = time.strftime("%e-%H")
        count[key] = 0
      end
    when :today
      time_start = Time.now.beginning_of_day.to_i
      Range.new(time_start, time_end).step(1.hour) do |seconds_since_epoch|
        time = Time.at(seconds_since_epoch)
        key = time.strftime("%e-%H")
        count[key] = 0
      end
    when :yesterday
      time_end   = (Time.now-1.day).end_of_day.to_i
      time_start = (Time.now-1.day).beginning_of_day.to_i
      Range.new(time_start, time_end).step(1.hour) do |seconds_since_epoch|
        time = Time.at(seconds_since_epoch)
        key = time.strftime("%e-%H")
        count[key] = 0
      end
    when :before_1_yesterday
      time_end   = (Time.now-2.day).end_of_day.to_i
      time_start = (Time.now-2.day).beginning_of_day.to_i
      Range.new(time_start, time_end).step(1.hour) do |seconds_since_epoch|
        time = Time.at(seconds_since_epoch)
        key = time.strftime("%e-%H")
        count[key] = 0
      end
    when :before_2_yesterday
      time_end   = (Time.now-3.day).end_of_day.to_i
      time_start = (Time.now-3.day).beginning_of_day.to_i
      Range.new(time_start, time_end).step(1.hour) do |seconds_since_epoch|
        time = Time.at(seconds_since_epoch)
        key = time.strftime("%e-%H")
        count[key] = 0
      end
    when :before_3_yesterday
      time_end   = (Time.now-4.day).end_of_day.to_i
      time_start = (Time.now-4.day).beginning_of_day.to_i
      Range.new(time_start, time_end).step(1.hour) do |seconds_since_epoch|
        time = Time.at(seconds_since_epoch)
        key = time.strftime("%e-%H")
        count[key] = 0
      end
    when :before_4_yesterday
      time_end   = (Time.now-5.day).end_of_day.to_i
      time_start = (Time.now-5.day).beginning_of_day.to_i
      Range.new(time_start, time_end).step(1.hour) do |seconds_since_epoch|
        time = Time.at(seconds_since_epoch)
        key = time.strftime("%e-%H")
        count[key] = 0
      end
    when :last_week
      time_start = Time.now.to_i - 1.week
      Range.new(time_start, time_end).step(1.day) do |seconds_since_epoch|
        time = Time.at(seconds_since_epoch)
        key = time.strftime("%m-%d")
        count[key] = 0
      end
    when :last_month
      time_start = (Time.now - 1.month).to_i
      time_end = (Time.now - 1.day).to_i
      Range.new(time_start, time_end).step(1.day) do |seconds_since_epoch|
        time = Time.at(seconds_since_epoch)
        key = time.strftime("%m-%d")
        count[key] = 0
      end
    when :last_quarter
      time_start = (Time.now - 3.months).to_i
      time_end = (Time.now - 1.day).to_i
      Range.new(time_start, time_end).step(1.day) do |seconds_since_epoch|
        time = Time.at(seconds_since_epoch)
        key =  time.strftime("%Y-%m-%d")
        count[key] = 0
      end
    when :last_year
      time_end = Date.today
      time_start = time_end - 1.year

      count[time_start.strftime("%Y-%m")] = 0

      while time_start < time_end
        time_start >>= 1
        count[time_start.strftime("%Y-%m")] = 0       
      end

    end
    count
  end

  def self.cache_for_type(collection, type=:hour, sensor=false)
    return collection.group_by { |x| x.ran_at.strftime("%e-%H") } unless sensor
    return collection.all(:sid => sensor.sid).group_by do |x| 
      x.ran_at.strftime("%e-%H")
    end
  end

  def self.range_for_type(type=:hour, &block)
    Range.new(Time.now.beginning_of_day.to_i, Time.now.end_of_day.to_i).step(1.hour) do |seconds_since_epoch|
      time = Time.at(seconds_since_epoch)
      key = time.strftime("%e-%H")
      block.call(key) if block
    end
  end

end
