module Snorby
  module Jobs
    class SensorUpdateDbversionJob < Struct.new(:dbversion_id, :verbose)
      include Snorby::Jobs::CacheHelper
      
      def perform
        dbversion = RuleDbversion.get(dbversion_id.to_i) unless dbversion_id.nil?
        unless dbversion.nil?
          Sensor.update_all_dbversion(dbversion.id)
          dbversions = Sensor.current_dbversions
          if dbversions.size > 1 or (dbversions.size == 1 and dbversions.first != dbversion)
            Snorby::Jobs.sensor_update_dbversion.destroy! if Snorby::Jobs.sensor_update_dbversion?
            Delayed::Job.enqueue(Snorby::Jobs::SensorUpdateDbversionJob.new(dbversion_id, true), 
                                :priority => 15, :run_at => 5.seconds.from_now)
          end
        else
          logit "dbversion cannot be null"
        end
      rescue => e
        puts e
        puts e.backtrace
      end
    end
  end
end
