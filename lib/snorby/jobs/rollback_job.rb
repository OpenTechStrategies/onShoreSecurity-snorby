module Snorby
  module Jobs

    class RollbackJob < Struct.new(:sensor_sid, :compilation_id, :user_id, :verbose)

      include Snorby::Jobs::CacheHelper

      def perform
        
        sensor = Sensor.get(sensor_sid)
        
        begin
          sensor.all_childs(true).select{|s1| s1.domain}.each{|s2| s2.update(:compiling => true)}
          new_compilation = Sensor.rollback_rules(sensor_sid, compilation_id, user_id)
          unless new_compilation.nil?
            Sensor.compile_rules(sensor_sid, user_id, new_compilation, false)
            
            sensor.virtual_sensors.each do |x|
              x.download_rules
            end
          end
          
        rescue => e
          logit "Sensor: #{Sensor.get(sensor_sid)} #{e}"
        ensure
          sensor.all_childs(true).select{|s1| s1.domain}.each{|s2| s2.update(:compiling => false)}
        end
        
      end
    end
  end
end