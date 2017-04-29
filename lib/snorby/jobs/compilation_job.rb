module Snorby
  module Jobs

    class CompilationJob < Struct.new(:sensor_sid, :user_id, :compilation_name, :sync_sensor, :updated_parent, :verbose)

      include Snorby::Jobs::CacheHelper

      def perform

        @sensor = Sensor.get(sensor_sid)

        return false if @sensor.compiling

        begin
          @sensor.all_childs(true).select{|s1| s1.domain and !s1.deleted}.each{|s2| s2.update(:compiling => true)}
          Sensor.compile_rules(sensor_sid, user_id, compilation_name, updated_parent)
          if sync_sensor
            @sensor.virtual_sensors.each do |x|
              x.download_rules
            end
          end

        rescue => e
          logit "Sensor: #{Sensor.get(sensor_sid).name} #{e}"

        ensure
          @sensor.all_childs(true).select{|s1| s1.domain and !s1.deleted}.each{|s2| s2.update(:compiling => false)}
        end

      end
    end
  end
end