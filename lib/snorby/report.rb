module Snorby
  
  module Report
    
    include Rails.application.routes.url_helpers # brings ActionDispatch::Routing::UrlFor
    include ActionView::Helpers::TagHelper
    
    def self.build_report(range='yesterday', sids=nil)
      @range = range

      set_defaults(sids)

      @src_metrics       = @cache.src_metrics
      @dst_metrics       = @cache.dst_metrics
      @tcp               = @cache.protocol_count(:tcp, @range.to_sym)
      @udp               = @cache.protocol_count(:udp, @range.to_sym)
      @icmp              = @cache.protocol_count(:icmp, @range.to_sym)
      @high              = @cache.severity_count(:high, @range.to_sym)
      @medium            = @cache.severity_count(:medium, @range.to_sym)
      @low               = @cache.severity_count(:low, @range.to_sym)
      @sensor_metrics    = @cache.sensor_metrics(@range.to_sym)
      @signature_metrics = @cache.signature_metrics
      @event_count       = @cache.all.map(&:event_count).sum
      @axis              = Cache.count_hash(@range.to_sym).keys
      @classifications   = Classification.all(:order => [:events_count.desc])

      #TOP sensors
      unless sids.nil?
        @sensors = Sensor.all(:limit => 10, :order => [:events_count.desc])
      else
        @sensors = Sensor.all(:sid => sids, :limit => 10, :order => [:events_count.desc])
      end

      @last_cache = @cache.get_last ? @cache.get_last.ran_at : Time.now

        sigs = Event.all(:limit => 10, :order => [:timestamp.desc], 
                         :fields => [:sig_id], 
                         :unique => true).map(&:signature).map(&:sig_id)
      
      av = ActionView::Base.new(Rails.root.join('app', 'views'))
      av.assign({
        :range => @range,
        :start_time => @start_time,
        :end_time => @end_time,
        :cache => @cache,
        :src_metrics => @src_metrics,
        :dst_metrics => @dst_metrics,
        :tcp => @tcp,
        :udp => @udp,
        :icmp => @icmp,
        :high => @high,
        :medium => @medium,
        :low => @low,
        :sensor_metrics => @sensor_metrics,
        :signature_metrics => @signature_metrics,
        :event_count => @event_count,
        :axis => @axis,
	:classifications => @classifications,
        :last_cache => @last_cache
      })

        pdf = PDFKit.new(av.render(:template => "page/dashboard.pdf.erb", 
                                   :layout => 'layouts/pdf.html.erb'))

      pdf.stylesheets << Rails.root.join("public/stylesheets/pdf.css")
      
      data = {
        :start_time => @start_time,
        :end_time => @end_time,
        :pdf => pdf.to_pdf
      }
      
      return data
    end

    def self.set_defaults(sids=nil)
      @now = Time.now

      case @range.to_sym
      when :last_24      
        @start_time = @now.yesterday
        @end_time = @now      
        @cache = Cache.last_24(@start_time, @end_time)
      when :today
        @cache = Cache.today
        @start_time = @now.beginning_of_day
        @end_time = @now.end_of_day
      when :yesterday
        @cache = Cache.yesterday
        @start_time = (@now - 1.day).beginning_of_day
        @end_time = (@now - 1.day).end_of_day
      when :week
        @cache = DailyCache.this_week
        @start_time = @now.beginning_of_week
        @end_time = @now.end_of_week
      when :last_week
        @cache = DailyCache.last_week
        @start_time = (@now - 1.day).end_of_day - 1.week
        @end_time = (@now - 1.day).end_of_day
      when :month
        @cache = DailyCache.this_month
        @start_time = @now.beginning_of_month
        @end_time = @now.end_of_month
      when :last_month
        @cache = DailyCache.last_month
        @start_time = @now - 1.months
        @end_time = @now
      when :quarter
        @cache = DailyCache.this_quarter
        @start_time = @now.beginning_of_quarter
        @end_time = @now.end_of_quarter
      when :last_quarter
        @cache = DailyCache.last_quarter
        @start_time = @now - 3.months
        @end_time = @now
      when :year
        @cache = DailyCache.this_year
        @start_time = @now.beginning_of_year
        @end_time = @now.end_of_year
      when :last_year
        @cache = DailyCache.last_year
        @start_time = @now - 1.year
        @end_time = @now
      else
        @cache = Cache.today
        @start_time = @now.beginning_of_day
        @end_time = @now.end_of_day
      end
      
      @cache = @cache.all(:sid => sids) unless sids.nil?
      
    end
  end
end
