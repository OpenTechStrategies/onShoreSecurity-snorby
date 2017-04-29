module Snorby
  module Jobs

    class SnmpJob < Struct.new(:verbose)

      include Snorby::Jobs::CacheHelper

      def perform

        time = Snorby::CONFIG_SNMP[:time].to_f

        Sensor.all.select{|x| x.virtual_sensor and x.ipdir.present?}.each do |sensor|

          @sensor = sensor
          @node   = sensor.chef_node

          # Stadistic values from sensor
          Snorby::CONFIG_SNMP[:oids].each_key do |oid|
            begin
              if Snorby::CONFIG_SNMP[:oids][oid].has_key? "reference"
                value = Snmp.get_value(sensor.ipdir, oid, Snorby::CONFIG_SNMP[:oids][oid]["reference"],
                                                          Snorby::CONFIG_SNMP[:oids][oid]["mult"],
                                                          Snorby::CONFIG_SNMP[:oids][oid]["inverse"])
              elsif Snorby::CONFIG_SNMP[:oids][oid].has_key? "minus"
                value = Snorby::CONFIG_SNMP[:oids][oid]["minus"].to_i - Snmp.get_value(sensor.ipdir, oid)
              else
                value = Snmp.get_value(sensor.ipdir, oid)
              end
              Snmp.create(:sid => sensor.sid, :timestamp => Time.now, :snmp_key => oid, :value => value, :snmp_type => 'snmp_statistics')
            rescue => e
              logit "Snmp: #{e}"
            end
          end
          
          # Stadistic values from Snort       
          begin
            values = SnortStat.get_value(sensor.ipdir, Snorby::CONFIG_SNMP[:snort_stats_oid])

            values.each_key do |instance|
              time_at = Time.at(values[instance]["time"].to_i)

              time_at = time_at - (time_at.min%5).minutes - time_at.sec

              values[instance].each do |name, val|
                
                snort_stat_name = SnortStatName.first_or_create(:name => name)
                
                if name != "time"
                  begin
                    SnortStat.create(:sid => sensor.sid, :timestamp => time_at, :instance => instance, :snort_stat_name_id => snort_stat_name.id, :value => val.to_f)
                  rescue => e
                  end
                end
              end
            end
          rescue => e
            logit "SnortStat: #{e}"
          end

          # Stadistic values from Snort
          begin
            segments = @node["redBorder"]["segments"].keys

            #time_at = Time.now - (now.min%5).minutes - now.sec

            segments.each do |segment|

              index = segment.match(/\d+$/)

              if index.present?

                index = index[0].to_i

                # from bytes to Mbits
                value = Snmp.get_value(sensor.ipdir, "1.3.6.1.4.1.39483.1.3.#{index}.4.1.2.9.115.104.101.108.108.116.101.115.116.1").to_f * 8 / (1024 * 1024)
                Snmp.create(:sid => sensor.sid, :timestamp => Time.now, :snmp_key => segment, :value => value, :snmp_type => 'snmp_traffic')

              end
            
            end

          rescue => e
            logit "Snmp traffic: #{e}"
          end

        end  
        
        Snorby::Jobs.snmp.destroy! if Snorby::Jobs.snmp?
        
        Delayed::Job.enqueue(Snorby::Jobs::SnmpJob.new(false), :priority => 20, :run_at => Time.now + time.minutes)
        
      end
      
    end

  end
end  
  
