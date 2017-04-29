class EventsController < ApplicationController
  respond_to :html, :xml, :json, :js, :csv
  
  helper_method :sort_column, :sort_direction
  
  before_filter :lookups, :only => [:by_source_ip, :by_destination_ip, :ip_search]

  before_filter :require_administrative_privileges, :only => [:prune_view, :prune]

  # If the sensor is indicated in the REST path, it will show the events related to that sensor.
  # /sensors/:sensor_id/events
  def index

    params[:sort] = sort_column
    params[:direction] = sort_direction
    params[:format] = request.format

    if session[:filter] and session[:filter].length > 0

      params[:search] = session_to_params
      params[:match_all] = "true"

    end

    if params[:quick_search] and params[:quick_search][:text]

      @quick_search = params[:quick_search][:text]

      params[:quick_search] = {"0" => {:column => "signature_name", :operator => "contains", :value => "%#{@quick_search.split.join('%')}%"}}

      if /^(\d{1,3}\.){3}\d{1,3}$/ =~ @quick_search or /^(\d{1,3}\.){3}\d{1,3}\/\d+$/ =~ @quick_search

        params[:quick_search].merge!({"1" => {:column => "source_ip", :operator => "is", :value => @quick_search}, "2" => {:column => "destination_ip", :operator => "is", :value => @quick_search}})

      end

    end

    @events = Event.sorty(params)
    @classifications ||= Classification.all
    @filters = (SavedEventFilter.all(:user_id => @current_user.id, :limit => 5) | SavedEventFilter.all(:public => true, :limit => 5, :user_id.not => @current_user.id)).all(:order => :title)

    respond_to do |format|
      format.html {render :layout => true}
      format.js
      format.pdf do
        render :pdf => "OnGuard SIM - Listing Events", :template => "events/events_table.pdf.erb", :layout => 'pdf.html.erb', :stylesheets => ["pdf"]
      end
    end
  end

  def sessions
    @session_view = true

    params[:sort] = sort_column
    params[:direction] = sort_direction
    params[:format] = request.format

    if session[:filter] and session[:filter].length > 0
      params[:search] = session_to_params
      params[:match_all] = "true"
    end

    if params[:quick_search] and params[:quick_search][:text]
      @quick_search = params[:quick_search][:text]
      params[:quick_search] = {"0" => {:column => "signature_name", :operator => "contains", :value => "%#{@quick_search.split.join('%')}%"}}
      if /^(\d{1,3}\.){3}\d{1,3}$/ =~ @quick_search or /^(\d{1,3}\.){3}\d{1,3}\/\d+$/ =~ @quick_search
      params[:quick_search].merge!({"1" => {:column => "source_ip", :operator => "is", :value => @quick_search}, "2" => {:column => "destination_ip", :operator => "is", :value => @quick_search}})
      end
    end

    sql = %{
      select e.sid, e.cid, e.signature,
      e.classification_id, e.users_count,
      e.notes_count, e.timestamp, e.user_id,
      a.number_of_events from aggregated_events a
      inner join event e on a.event_id = e.id
    }

    sort = if [:sid,:signature,:timestamp].include?(params[:sort])
      "e.#{params[:sort]}"
    elsif params[:sort] == :sig_priority
      sql += "inner join signature s on e.signature = s.sig_id "
      "s.#{params[:sort]}"
    else
      "a.#{params[:sort]}"
    end

    sql += "order by #{sort} #{params[:direction]} limit ? offset ?"
   
    @events = Event.sorty(params, [sql], "select count(*) from aggregated_events;")

    @classifications ||= Classification.all

    respond_to do |format|
      format.html {render :layout => true}
      format.js
      format.json {render :json => {
        :events => @events.map(&:detailed_json),
        :classifications => @classifications,
        :pagination => {
          :total => @events.pager.total,
          :per_page => @events.pager.per_page,
          :current_page => @events.pager.current_page,
          :previous_page => @events.pager.previous_page,
          :next_page => @events.pager.next_page,
          :total_pages => @events.pager.total_pages
        }
      }}
    end
  end


  def queue
    params[:sort] = sort_column
    params[:direction] = sort_direction
    params[:classification_all] = true
    params[:user_events] = true

    @events ||= current_user.events.sorty(params)
    @classifications ||= Classification.all
    respond_to do |format|
      format.html {render :layout => true}
      format.js
      format.json {render :json => {
        :events => @events.map(&:detailed_json),
        :classifications => @classifications,
        :pagination => {
          :total => @events.pager.total,
          :per_page => @events.pager.per_page,
          :current_page => @events.pager.current_page,
          :previous_page => @events.pager.previous_page,
          :next_page => @events.pager.next_page,
          :total_pages => @events.pager.total_pages
        }
      }}
    end
  end

  def request_packet_capture
    @event = Event.get(params['sid'], params['cid'])
    @packet = @event.packet_capture(params)
    respond_to do |format|
      format.html {render :layout => false}
      format.js
    end
  end

  def rule
    @event = Event.get(params['sid'], params['cid'])
    @event.rule ? @rule = @event.rule : @rule = 'No rule found for this event.'

    respond_to do |format|
      format.html { render :layout => false }
    end
  end

  def show
    if params.has_key?(:sessions)
      @session_view = true
    end

    @event = Event.get(params['sid'], params['cid'])
    @lookups ||= Lookup.all
    @notes     = @event.notes.all.page(params[:page].to_i, :per_page => 5, :order => [:id.desc])
    @rule      = @event.rule
    @sensor    = @event.sensor
    @sensor    = @sensor.parent unless @sensor.virtual_sensor?

    unless @rule.nil?
      @suppress_rules  = @sensor.suppress_events_rules.select {|x| x.sig_sid==@rule.rule_id and x.sig_gid == @rule.gid}
      @limit_rules     = @sensor.limit_events_rules.select {|x| x.sig_sid==@rule.rule_id and x.sig_gid == @rule.gid}
      @rule_references = @rule.rule_references
      @rule_policies   = @rule.rule_policies unless @rule.nil?
      @rule_flowbits   = @rule.rule_flowbits unless @rule.nil?
    end

    respond_to do |format|
      format.html {render :layout => false}
      format.js
      format.pdf do
        render :pdf => "Event:#{@event.id}", 
               :template => "events/show.pdf.erb", 
               :layout => 'pdf.html.erb', :stylesheets => ["pdf"]
          end
      format.xml { render :xml => @event.in_xml }
      format.csv { render :text => @event.to_csv }
      format.json { render :json => {
        :event => @event.in_json,
        :notes => @notes.map(&:in_json)
      }}
    end
  end

  def show_map
    @ip = params[:ip]
    @map_data = Snorby::Geoip.latlong([@ip])
    render :layout => false
  end

  def view
    @events = Event.all(:sid => params['sid'], 
    :cid => params['cid']).page(params[:page].to_i, 
    :per_page => @current_user.per_page_count, :order => [:timestamp.desc])

    @classifications ||= Classification.all
  end

  def create_email
    @event = Event.get(params[:sid], params[:cid])
    render :layout => false
  end

  def email
    Delayed::Job.enqueue(Snorby::Jobs::EventMailerJob.new(params[:sid],
    params[:cid], params[:email]))

    respond_to do |format|
      format.html { render :layout => false }
      format.js
    end
  end

  def create_mass_action
    @event = Event.get(params[:sid], params[:cid])
    render :layout => false
  end

  def mass_action
    options = {}

    params[:reclassify] ? (reclassify = true) : (reclassify = false)
    params[:auto_class] ? (auto_class = true) : (auto_class = false)

    if params.has_key?(:sensor_ids) and params[:sensor_ids].is_a?(Array)
      sensors = params[:sensor_ids].select{|x| Sensor.get(x).present? }.map{|sensor| Sensor.get(sensor.to_i).real_sensors.select{|s| can?(:read, s)}.map(&:sid)}
      sensors.flatten!.uniq!
      options.merge!({:sid => sensors})
    else
      sensors = Sensor.root.real_sensors.select{|s| can?(:read, s)}.map(&:sid)
      options.merge!({:sid => sensors})
    end

    if params[:use_sig_id]
      sig_gid, sig_sid = params[:sig_id].split("-")
      signature_ids = Signature.all(:fields => [:sig_id], :sig_gid => sig_gid.to_i, :sig_sid => sig_sid.to_i).map(&:sig_id)
      options.merge!({:sig_id => signature_ids})
    end
    
    options.merge!({
      :"ip.ip_src" => IPAddr.new(params[:ip_src].to_i,Socket::AF_INET)
    }) if params[:use_ip_src]
    
    options.merge!({
      :"ip.ip_dst" => IPAddr.new(params[:ip_dst].to_i,Socket::AF_INET)
    }) if params[:use_ip_dst]

    if options.empty?
      render :js => "flash_message.push({type: 'error', message: 'Sorry," +
        " Insufficient classification parameters submitted...'});flash();"
    else
      if auto_class and User.current_user.admin
        auto_class_options = {}

        if params[:use_sig_id]
          signature = Signature.get(params[:sig_id])
          auto_class_options.merge!({:sig_gid => signature.sig_gid.to_i, :sig_sid => signature.sig_sid.to_i})
        end

        auto_class_options.merge!({:ip_src => IPAddr.new(params[:ip_src].to_i, Socket::AF_INET).to_s}) if params[:use_ip_src]

        auto_class_options.merge!({:ip_dst => IPAddr.new(params[:ip_dst].to_i, Socket::AF_INET).to_s}) if params[:use_ip_dst]

        auto_class_options.merge!({:classification_id => params[:classification_id].to_i})

        if params.has_key?(:sensor_ids) and params[:sensor_ids].is_a?(Array)
          params[:sensor_ids].each do |sensor|
            # to prevent duplicates entries in auto classifications
            AutoClassification.first_or_create(auto_class_options.merge({:sid => sensor}))
          end
        else
          AutoClassification.first_or_create(auto_class_options)
        end

      end

      Delayed::Job.enqueue(Snorby::Jobs::MassClassification.new(params[:classification_id], options, User.current_user.id, reclassify))
      respond_to do |format|
        format.html { render :layout => false }
        format.js
      end
    end
  end

  def filtered_events
    @sensor = Sensor.get(params[:sid])
    @sensor = @sensor.parent unless @sensor.virtual_sensor?

    if can?(:manage, @sensor)    
      @suppress_rules = @sensor.event_filterings(:order => :position)
    end

    render :layout => false
  end

  def filter_event
    @sensor = Sensor.get(params[:sid])
    @sensor = @sensor.parent unless @sensor.virtual_sensor?

    if can?(:manage, @sensor)
      @rule = Rule.first(:rule_id => params[:sig_sid], :gid => params[:sig_gid], :dbversion_id => @sensor.dbversion_id)
      @rule = Rule.first(:rule_id => params[:sig_sid], :gid => params[:sig_gid]) if @rule.nil?
      @event_filtering = EventFiltering.first(:sid => @sensor.sid, :sig_sid => params[:sig_sid], :sig_gid => params[:sig_gid])
      if params[:suppress]
        @event = Event.get(params[:sid], params[:cid])
        @suppress_rules  = @sensor.suppress_events_rules.select {|x| x.sig_sid==params[:sig_sid] and x.sig_gid == params[:sig_gid]}
        render :template => 'events/suppress_event.html.erb', :layout => false
      else
        render :layout => false
      end
    else 
      render :file => "public/404.html", :status => 404
    end
  end


  def create_filter_event
    @sensor = Sensor.get(params[:e_filter][:sid])
    @sensor = @sensor.parent unless @sensor.virtual_sensor?

    if cannot?(:manage, @sensor)
      render :file => "public/404.html", :status => 404
    else
      @event_filtering = EventFiltering.first(:sid => params[:e_filter][:sid], 
                                              :sig_sid => params[:e_filter][:sig_sid], 
                                              :sig_gid => params[:e_filter][:sig_gid])

      if @event_filtering.nil?
        @event_filtering = EventFiltering.create(params[:e_filter])
      elsif params[:e_filter][:filtering_type].to_s == 'suppress'
        params[:e_filter][:tracked_ip].split(',').each do |e|
          @event_filtering = EventFiltering.create(:sid           => params[:e_filter][:sid],  
                                                  :sig_sid        => params[:e_filter][:sig_sid], 
                                                  :sig_gid        => params[:e_filter][:sig_gid], 
                                                  :filtering_type => params[:e_filter][:filtering_type], 
                                                  :tracked_type   => params[:e_filter][:tracked_type],
                                                  :tracked_ip     => NetAddr::CIDR.create(e.strip).to_s.gsub('/32',''))
        end
      else
        @event_filtering.update(params[:e_filter])
      end

      rule = Rule.first(:rule_id => params[:e_filter][:sig_sid], 
                        :gid => params[:e_filter][:sig_gid], 
                        :dbversion_id => @sensor.dbversion_id)

      if params[:e_filter][:filtering_type].to_s == 'suppress'
        @suppress_rules  = @sensor.suppress_events_rules.select {|x| x.sig_sid==rule.rule_id and x.sig_gid == rule.gid}
      else
        @limit_rules     = @sensor.limit_events_rules.select {|x| x.sig_sid==rule.rule_id and x.sig_gid == rule.gid}
      end
    end              
  end

  def delete_filter_event
    @event_filtering = EventFiltering.get(params[:id])
    @sensor          = @event_filtering.sensor
    @sensor          = @sensor.parent unless @sensor.virtual_sensor?

    if cannot?(:manage, @sensor)
      render :file => "public/404.html", :status => 404
    else

      if @event_filtering.filtering_type == 'suppress'
        sid = @event_filtering.sig_sid
        gid = @event_filtering.sig_gid
        @event_filtering.destroy
        @suppress_rules  = @sensor.suppress_events_rules.select {|x| x.sig_sid==sid and x.sig_gid == gid}
      else
        @event_filtering.destroy
        render :js => "$('tr##{@event_filtering.id}').fadeOut();" +
                    "$('tr##{@event_filtering.id}').remove();"
      end
    end
  end

  def export
    @events = Event.find_by_ids(params[:events])

    respond_to do |format|
      format.json { render :json => @events }
      format.xml { render :xml => @events }
      format.csv { render :json => @events.to_csv }
    end
  end

  def history
    @events = Event.all(:user_id => @current_user.id).page(params[:page].to_i, 
    :per_page => @current_user.per_page_count, :order => [:timestamp.desc])
    @classifications ||= Classification.all
  end

  def classify
    @events = Event.find_by_ids(params[:events]).select{|e| can? :manage, e.sensor}
    Event.classify_from_collection(@events, params[:classification].to_i, User.current_user.id, true)
    respond_to do |format|
      format.html { render :layout => false, :status => 200 }
      format.json { render :json => { :status => 'success' }}
    end
  end

  def classify_sessions
    if params[:events]
      Event.update_classification_by_session(params[:events], params[:classification].to_i, User.current_user.id)
    end

    respond_to do |format|
      format.html { render :layout => false, :status => 200 }
      format.json { render :json => { :status => 'success' }}
    end
  end

  def mass_create_favorite
    @events ||= Event.find_by_ids(params[:events])
    @events.each { |event| event.create_favorite unless favorite? }
    render :json => {}
  end

  def mass_destroy_favorite
    @events ||= Event.find_by_ids(params[:events])
    @events.each { |event| event.destroy_favorite if favorite? }
    render :json => {}
  end

  def last
    render :json => { :time => Event.last_event_timestamp }
  end

  def since
    @events = Event.to_json_since(params[:timestamp])
    render :json => @events.to_json
  end

  def favorite
    @event = Event.get(params[:sid], params[:cid])
    @event.toggle_favorite
    render :json => {}
  end

  def lookup
    if Setting.lookups?
      @lookup = Snorby::Lookup.new(params[:address])
      render :layout => false
    else
      render :text => '<div id="note-box">This feature has been disabled</div>'.html_safe, :notice => 'This feature has been disabled'
    end
  end

  def activity
    @user = User.get(params[:user_id])
    @user = @current_user unless @user

    @events = @user.events.page(params[:page].to_i, :per_page => @current_user.per_page_count, 
              :order => [:timestamp.desc])

    @classifications ||= Classification.all
  end

  def hotkey
    @classifications ||= Classification.all
    respond_to do |format|
      format.html {render :layout => false}
      format.js
    end
  end

  def packet_capture
    @event = Event.get(params[:sid], params[:cid])
    render :layout => false
  end
  
  def by_sensor
    params[:page] = params[:page].to_i || 1
    offset = (params[:page] - 1) * current_user.per_page_count

    # We need to make two sensor queries. First, for getting sensors whith read privileges, generating an array. Second, for getting a DataMapper object.
    array_sensor = Sensor.all(:virtual_sensor => true, :deleted => false).select{|s| can?(:read, s)}.map(&:sid)

    @sensors = Sensor.all(:sid => array_sensor)
    @sensors.sort!{|x, y| y.events_count <=> x.events_count}

    options = { :limit => current_user.per_page_count, :offset => offset, :total => @sensors.count, :page => params[:page] }
    @sensors.pager = DataMapper::Pager.new options
  end
  
  def by_source_ip
    by_ip(:src_ips)
  end
  
  def by_destination_ip
    by_ip(:dst_ips)
  end

  def ip_search
    @type = params[:type] == "src_ips" ? "ip_src" : "ip_dst"
    @type_text = params[:type] == "src_ips" ? "Source IP" : "Destination IP"    

    if params[:q]
      by_ip(params[:type].to_sym, params[:q])
    else
      @ips = {:collection => [], :page => 1, :total => 1, :limit => 25}
      @total_event_count = 0
    end
  end

  def prune_view
    @sensors = Sensor.all(:domain => true).select{|s| !s.is_root?}
    render :layout => false
  end

  def prune
    params.delete_if{|key, value| value.blank?}
    @message = ['success', 'Prune action enqueued.']
    Delayed::Job.enqueue(Snorby::Jobs::PruneEventsJob.new(params[:sid], params[:timestamp_gte], params[:timestamp_lte], true))
  end

  def update_events_count

    params.delete_if{|key, value| value.blank?}

    sensor = if params[:sensor_sid]
      Sensor.get(params[:sensor_sid])
    else
      Sensor.root
    end

    search = {}

    search.merge!(:timestamp.lte => Chronic.parse(params[:end_date]).end_of_day) unless params[:end_date].nil?
    search.merge!(:timestamp.gte => Chronic.parse(params[:start_date]).beginning_of_day) unless params[:start_date].nil?

    @events = sensor.events.all(search)

    render :text => "#{@events.count} Events"
  end

  def order_auto
    order = params[:positions].split(";")
    order.each_with_index do |auto_id, position|
      EventFiltering.get(auto_id).update(:position => (position + 1))
    end
  end

  private

  def sort_column
    return :timestamp unless params.has_key?(:sort)
    return params[:sort].to_sym if Event::SORT.has_key?(params[:sort].to_sym)

    :timestamp
  end
  
  def sort_direction
    %w[asc desc].include?(params[:direction].to_s) ? params[:direction].to_sym : :desc
  end
  
  def lookups
    @lookups ||= Lookup.all
  end
  
  def by_ip(type, ip_search=false)
    @ips = {}
    top = []

    real_sensors = Sensor.all(:virtual_sensor => false, :virtual_sensor => false).select{|s| can?(:read, s)}.map(&:sid)

    cache = DailyCache.all(:sid => real_sensors).map(&type).compact
    @total_event_count = 0

    cache.each do |ip_hash|

      ip_hash.each do |ip, count|

        if (ip_search and ip.include? ip_search) or !ip_search
          if @ips.has_key?(ip)
            @ips[ip] += count
          else
            @ips.merge!({ip => count})
          end
        end
          
        @total_event_count += count
      end
    end

    @ips.sort{ |a,b| b[1] <=> a[1] }.each{|data| top << data}
    
    current_page = (params[:page] || 1).to_i
    per_page = User.current_user.per_page_count
    
    @ips = []
    
    top.each_slice(per_page){|x| @ips << x}
    
    @ips = {:collection => @ips[current_page - 1].nil? ? [] : @ips[current_page - 1], :page => current_page, :total => top.size, :limit => per_page}
  end

  def session_to_params

    params_aux = {}

    session[:filter].each do |k, v|
      
      v.each do |key, value|

        if k.to_s == "signature" and key.is_a?(Array)
          sig_ids = []
          key.each do |sig|
            if /^\d+-\d+$/.match(sig)
              sig_gid, sig_sid = sig.split("-")
              sig_ids << Signature.all(:fields => [:sig_id], :sig_gid => sig_gid, :sig_sid => sig_sid).map(&:sig_id)
            else
              sig_ids << sig
            end
          end
          key = sig_ids.flatten
        elsif k.to_s == "signature"
          if /^\d+-\d+$/.match(key)
            sig_gid, sig_sid = key.split("-")
            key = Signature.all(:fields => [:sig_id], :sig_gid => sig_gid, :sig_sid => sig_sid).map(&:sig_id)
          end
        end

        if params_aux[k] and params_aux[k][value[:operator]]
          params_aux[k][value[:operator]] = [params_aux[k][value[:operator]]] unless params_aux[k][value[:operator]].kind_of?(Array)
          params_aux[k][value[:operator]] << key
        elsif params_aux[k]
          params_aux[k].merge!({value[:operator] => key})
        else
          params_aux[k] = {value[:operator] => key}
        end

      end

    end

    params_search = {}
    count = 0
    hash_tmp = {}

    params_aux.each do |k, v|
      v.each do |key, value|
        
        if key.to_sym == :is and value.is_a?(Array)
          params_search[count.to_s] = {"column" => k, "operator" => "in", "value" => value}
        elsif value.is_a?(Array)
          params_search[count.to_s] = {"column" => k, "operator" => key, "value" => value.first}

          value[1..value.length - 1].each do |s|
            count += 1
            hash_tmp[count.to_s] = {"column" => k, "operator" => key, "value" => s}
          end
        else
          params_search[count.to_s] = {"column" => k, "operator" => key, "value" => value}
        end
        
        count += 1
      end
    end

    params_search.merge!(hash_tmp)

    params_search

  end

end
