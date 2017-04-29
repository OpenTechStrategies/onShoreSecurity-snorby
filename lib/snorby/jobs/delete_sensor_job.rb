module Snorby
  module Jobs

    class DeleteSensorJob < Struct.new(:sensor_sid, :user_id, :verbose)

      include Snorby::Jobs::CacheHelper

      def perform
        
        @sensor = Sensor.get(sensor_sid)
        User.current_user = User.get(user_id)

        begin

          @sensor.all_childs(true, true).each do |sensor|
            
            if sensor.domain
              begin
                client = sensor.chef_client
                client.destroy unless client.nil?
              rescue
                #client not found. Ignore it
              end
              begin
                node = sensor.chef_node
                node.destroy unless node.nil?
              rescue
                #node not found. Ignore it
              end
              begin
                role = sensor.chef_role
                role.destroy unless role.nil?
              rescue
                #role not found. Ignore it
              end

              begin
                if (sensor.virtual_sensor and Sensor.all(:ipdir => sensor.ipdir).count <= 1)
                  sensor.disassociate_sensor 
                end
              rescue

              end
            end

            delete_sensor(sensor.sid)

          end
          
        rescue => e
          logit "Sensor: #{Sensor.get(sensor_sid)} #{e}"
        end
        
      end
    end
  end
end