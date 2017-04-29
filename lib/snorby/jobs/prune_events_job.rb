module Snorby
  module Jobs

    class PruneEventsJob < Struct.new(:sensor_sid, :start_date, :end_date, :verbose)

      include Snorby::Jobs::CacheHelper

      def perform

        @sensor = if sensor_sid
          Sensor.get(sensor_sid)
        else
          Sensor.root
        end

        begin
          
          end_date_tmp    = Chronic.parse(end_date).end_of_day
          start_date_tmp  = Chronic.parse(start_date).beginning_of_day unless start_date.nil?
          real_sensors    = @sensor.real_sensors.map{|s| s.sid}

          search = {:sid => real_sensors}
          search.merge!(:timestamp.lte => end_date_tmp)
          search.merge!(:timestamp.gte => start_date_tmp) unless start_date.nil?
          search.merge!(:order => [:timestamp.asc])

          while Event.all(search).count > 0

            sql = %{ DELETE FROM event
                            WHERE sid in (#{real_sensors.join(", ")})
                            AND timestamp <= '#{end_date_tmp}' }

            sql += %{ AND timestamp >= '{start_date_tmp}'} unless start_date.nil?

            sql += %{ ORDER BY timestamp ASC }

            sql += %{ LIMIT 5000 }

            db_execute(sql)

            #Event.all(search.merge(:limit => 1000)).destroy

          end



        rescue => e
          logit "#{e}"
        end

      end

    end
  end
end