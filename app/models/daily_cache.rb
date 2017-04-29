class DailyCache < Snorby::Model::Types::EventMain

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

  def self.cache_time
    return get_last.ran_at if get_last
  end

  def self.get_last
    first(:order => [:ran_at.desc])
  end

  def self.this_year
    all(:ran_at.gte => Time.now.beginning_of_year.utc, :ran_at.lte => Time.now.end_of_year.utc)
  end

  def self.last_year
    all(:ran_at.gte => Time.now - 1.year, :ran_at.lt => Time.now)
  end

  def self.this_quarter
    all(:ran_at.gte => Time.now.beginning_of_quarter.utc, :ran_at.lte => Time.now.end_of_quarter.utc)
  end

    def self.last_quarter
    all(:ran_at.gte => Time.now - 3.months, :ran_at.lt => Time.now.beginning_of_day.utc)
  end

  def self.last_month
    all(:ran_at.gte => Time.now - 1.months, :ran_at.lt => Time.now.beginning_of_day.utc)
  end

  def self.this_month
    all(:ran_at.gte => Time.now.beginning_of_month.utc, :ran_at.lte => Time.now.end_of_month.utc)
  end

  def self.last_week
    all(:ran_at.gte => Time.now - 1.week, :ran_at.lt => Time.now.beginning_of_day.utc)
  end

  def self.this_week
    all(:ran_at.gte => Time.now.beginning_of_week.utc, :ran_at.lte => Time.now.end_of_week.utc)
  end

  def self.yesterday
    all(:ran_at.gte => Time.now.yesterday.beginning_of_day.utc, :ran_at.lt => Time.now.yesterday.end_of_day.utc)
  end

  def severities
    severities = []
    severity_metrics.each do |id, count|
      severities << [Severity.get(id).name, count]
    end
    severities.to_json
  end

  def self.protocol_count(protocol, type=:week)
    count = []

    @cache = cache_for_type(self, type)

    if @cache.empty?

      range_for_type(type) do |i|
        count << 0
      end

    else

      range_for_type(type) do |i|
        if @cache.has_key?(i)
          count << @cache[i].map(&:"#{protocol}_count").sum
        else
          count << 0
        end
      end

    end

    count
  end

  def self.severity_count(severity, type=:week, bar=false)
    count = []

    if bar and type == :last_quarter
      @cache = cache_for_type_quarter(self)
    else
      @cache = cache_for_type(self, type)
    end

    severity_type = {
      :high => 1,
      :medium => 2,
      :low => 3
    }

    if @cache.empty?
      if bar and type == :last_quarter
        range_for_type_quarter do |i|
          count << 0
        end
      else  
        range_for_type(type) do |i|
          count << 0
        end
      end
    else

      if bar and type == :last_quarter
        range_for_type_quarter do |i|

          if @cache.has_key?(i)
            sev_count = 0
            
            @cache[i].map(&:severity_metrics).each do |x|
              sev_count += (x.kind_of?(Hash) ? (x.has_key?(severity_type[severity.to_sym]) ? x[severity_type[severity.to_sym]] : 0) : 0)
            end

            count << sev_count

          else
            count << 0
          end
        end
      else
        range_for_type(type) do |i|

          if @cache.has_key?(i)
            sev_count = 0
            
            @cache[i].map(&:severity_metrics).each do |x|
              sev_count += (x.kind_of?(Hash) ? (x.has_key?(severity_type[severity.to_sym]) ? x[severity_type[severity.to_sym]] : 0) : 0)
            end

            count << sev_count

          else
            count << 0
          end
        end
      end
    end

    count
  end

  def self.sensor_metrics(type=:week)
    @metrics = []

    sensors = {}
    
    self.aggregate(:sid, :event_count.sum)
          .select{|c| Sensor.get(c[0]) and !Sensor.get(c[0]).domain}
            .group_by{|c| Sensor.get(c[0]).parent}.each_pair do |k, v|
      sensors[k] = v.map{|a| a[1]}.sum
    end

    sensors = sensors.sort{|s1, s2| s2[1] <=> s1[1]}.map{|s| s[0]}.first(10)

    sensors.each do |sensor|
      count = []
      time_range = []

      if User.current_user
      
        ability = Ability.new(User.current_user)
      
        if ability.cannot?(:read, sensor)
          next
        end
      end
      
      @cache = cache_for_type(self, type, sensor)

      if @cache.empty?

        range_for_type(type) do |i|
          time_range << "'#{i}'"
          count << 0
        end

      else

        range_for_type(type) do |i|
          time_range << "'#{i}'"

          if @cache.has_key?(i)
            count << @cache[i].map(&:event_count).sum
          else
            count << 0
          end

        end

      end
      
      #unless count.sum == 0
      @metrics << { :sid => sensor.sid, :name => sensor.sensor_name, :data => count }
      #end
    end

    @metrics
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

  def self.cache_for_type(collection, type=:week, sensor=false)
    case type.to_sym
    when :week, :last_week
      return collection.group_by { |x| x.ran_at.strftime('%m-%d') } unless sensor
      return collection.all(:sid => sensor.childs.map(&:sid)).group_by { |x| x.ran_at.strftime('%m-%d') }
    when :month, :last_month
      return collection.group_by { |x| x.ran_at.strftime('%m-%d') } unless sensor
      return collection.all(:sid => sensor.childs.map(&:sid)).group_by { |x| x.ran_at.strftime('%m-%d') }
    when :year, :quarter
      return collection.group_by { |x| x.ran_at.month } unless sensor
      return collection.all(:sid => sensor.childs.map(&:sid)).group_by { |x| x.ran_at.month }
    when :last_quarter
      return collection.group_by { |x| x.ran_at.strftime("%Y-%m-%d") } unless sensor
      return collection.all(:sid => sensor.childs.map(&:sid)).group_by { |x| x.ran_at.strftime("%Y-%m-%d") }
    when :last_year
      return collection.group_by { |x| x.ran_at.strftime("%Y-%m") } unless sensor
      return collection.all(:sid => sensor.childs.map(&:sid)).group_by { |x| x.ran_at.strftime("%Y-%m") }
    else
      return collection.group_by { |x| x.ran_at.day } unless sensor
      return collection.all(:sid => sensor.childs.map(&:sid)).group_by { |x| x.ran_at.day }
    end
  end

  def self.cache_for_type_quarter(collection)
    collection.group_by { |x| x.ran_at.strftime("%V") }
  end

  def self.range_for_type(type=:week, &block)

    case type.to_sym
    when :week

      ((Time.now.beginning_of_week.to_date)..(Time.now.end_of_week.to_date)).to_a.each do |i|
        block.call(i.day) if block
      end

    when :last_week

      ((Time.now - 1.week).to_date..(Time.now - 1.day).to_date).to_a.each do |i|
        block.call(i.strftime('%m-%d')) if block
      end

    when :month

      ((Time.now.beginning_of_month.to_date)..(Time.now.end_of_month.to_date)).to_a.each do |i|
        block.call(i.day) if block
      end

    when :last_month

      ((Time.now - 1.month).to_date..(Time.now - 1.day).to_date).to_a.each do |i|
        block.call(i.strftime('%m-%d')) if block
      end

    when :quarter

      ((Time.now.beginning_of_quarter.month)..(Time.now.end_of_quarter.month)).to_a.each do |i|
        block.call(i) if block
      end

    when :last_quarter

      ((Time.now - 3.months).to_date..(Time.now - 1.day).to_date).to_a.each do |i|
        block.call(i.strftime("%Y-%m-%d")) if block
      end      

    when :year

      Time.now.beginning_of_year.month.upto(Time.now.end_of_year.month) do |i|
        block.call(i) if block
      end

    when :last_year

      year_month = ((Time.now - 1.year).to_date..Time.now.to_date).to_a.map{|x| x.strftime("%Y-%m")}.uniq

      year_month.each do |i|
        block.call(i) if block
      end

    else

      ((Time.now.beginning_of_week.to_date)..(Time.now.end_of_week.to_date)).to_a.each do |i|
        block.call(i.day) if block
      end

    end

  end

  def self.range_for_type_quarter(&block)

    week = ((Time.now - 3.months).to_date..(Time.now - 1.day).to_date).to_a.map{|x| x.strftime("%V")}.uniq

    week.each do |i|
      block.call(i) if block
    end 
  end

  def protos
    protos = []
    protos << ['TCP', tcp_count]
    protos << ['UDP', udp_count]
    protos << ['ICMP', icmp_count]
    protos.to_json
  end

end
