module Snorby
  module Jobs

    class Main < Struct.new(:verbose)

    	def perform

    		if !Jobs.sensor_cache?
    			# TODO: enviar mail
    			Delayed::Job.enqueue(Snorby::Jobs::SensorCacheJob.new(false), :priority => 5, :run_at => Time.now.to_datetime + 5.second)
    		end

    		if !Jobs.daily_cache?
    			# TODO: enviar mail
    			Delayed::Job.enqueue(Snorby::Jobs::DailyCacheJob.new(false), :priority => 10, :run_at => Time.now.tomorrow.to_datetime.beginning_of_day)
    		end

    		if !Jobs.snmp?
    			# TODO: enviar mail
      		Delayed::Job.enqueue(Snorby::Jobs::SnmpJob.new(true), :priority => 20, :run_at => Time.now.to_datetime + 5.second)
      	end

      	Snorby::Jobs.main.destroy! if Snorby::Jobs.main?

        Delayed::Job.enqueue(Snorby::Jobs::Main.new(false),
          :priority => 1, :run_at => Time.now.to_datetime + 1.minutes)

    	end

    end

  end
end
