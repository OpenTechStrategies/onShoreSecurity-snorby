class Trap

  include DataMapper::Resource

  property :id, Serial

  property :sid, Integer, :required => true
  property :ip, String
  property :port, Integer
  property :protocol, String
  property :hostname, String
  property :community, String
  property :message, String, :length => 512
  property :trigger, String, :length => 64
  property :timestamp, DateTime

  belongs_to :sensor, :parent_key => :sid,
    :child_key => :sid, :required => true
  
  SORT = {
    :ip => 'snmp',
    :hostname => 'snmp', 
    :timestamp => 'snmp'
  }
  
  def pretty_time
    return "#{timestamp.in_time_zone.strftime('%l:%M %p')}" if Date.today.to_date == timestamp.to_date
    "#{timestamp.in_time_zone.strftime('%m/%d/%Y')}"
  end    
  
  def self.sorty(params={})
    sort = params[:sort]
    direction = params[:direction]

    page = {
      :per_page => User.current_user.per_page_count
    }
    page.merge!(:sid => User.current_user.real_sensors.map{|x| x.sid} | User.current_user.virtual_sensors.map{|x| x.sid}) unless User.current_user.admin

    if SORT[sort].downcase == 'snmp'
      page.merge!(:order => sort.send(direction))
    else

      page.merge!(
        :order => [Trap.send(SORT[sort].to_sym).send(sort).send(direction), 
                   :timestamp.send(direction)],
        :links => [Trap.relationships[SORT[sort].to_s].inverse]
      )
    end
    
    if params.has_key?(:search)
      page.merge!(search(params[:search]))
    end

    page(params[:page].to_i, page)
  end
  
  def self.search(params)
    
    @search = {}

    unless params[:hostname].blank?
      @search.merge!({:hostname => params[:hostname]})
    end
    
    unless params[:port].blank?
      @search.merge!({:port => params[:port]})
    end
  
    unless params[:community].blank?
      @search.merge!({:community => params[:community]})
    end

    unless params[:message].blank?
      @search.merge!(:conditions => ["message LIKE ?", "%#{params[:message].split.join('%')}%"])
    end

    unless params[:trigger].blank?
      @search.merge!({:trigger => params[:trigger]})
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

  def self.protocols
    Trap.all(:fields => [:protocol], :unique => true, :protocol.not => nil).map{|r1| r1.protocol}
  end

  def self.communities
    Trap.all(:fields => [:community], :unique => true, :community.not => nil).map{|c1| c1.community}
  end

  def self.triggers
    Trap.all(:fields => [:trigger], :unique => true, :trigger.not => nil).map{|c1| c1.trigger}
  end
  

end
