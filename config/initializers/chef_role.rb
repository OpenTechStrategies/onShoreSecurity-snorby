Chef::Role.class_eval do

	def save
      begin
        
        if self.name.match(/-(\d+)$/)
	      	sensor_id = self.name.match(/-(\d+)$/)[1].to_i
	      	role = Sensor.get(sensor_id).chef_role
      	else
      		role = Sensor.manager_chef_role
      	end

        chef_server_rest.put_rest("roles/#{@name}", self)

        if User.current_user

			log_attributes = {:model_name => 'Sensor', :action => 'update', :model_id => sensor_id, :user => User.current_user}

			message = differences(role.override_attributes["redBorder"], self.override_attributes["redBorder"])

			log_attributes.merge!(:message => "Updated #{message.join(", ")}")

			Log.new(log_attributes).save unless message.blank?

        end

      rescue Net::HTTPServerException => e
        raise e unless e.response.code == "404"
        chef_server_rest.post_rest("roles", self)
      end
      self
    end

    private

	def differences(hash_one, hash_two, message=nil)

		message ||= []
		hash_one.each do |key, value|

			if value.is_a?(Hash)
				result = hash_one[key].diff(hash_two[key])
				message << result if !result.blank?
			end
		end

		message
	end

end