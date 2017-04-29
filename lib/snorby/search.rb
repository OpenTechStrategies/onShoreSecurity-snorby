module Snorby

  #
  # Search
  #
  module Search

    COLUMN = {
      :signature => "event.signature",
      :signature_name => "signature.sig_name",
      :severity => "signature.sig_priority",
      :source_ip => "iphdr.ip_src",
      :destination_ip => "iphdr.ip_dst",
      :tcp_source_port => "tcphdr.tcp_sport",
      :udp_source_port => "udphdr.udp_sport",
      :tcp_destination_port => "tcphdr.tcp_dport",
      :udp_destination_port => "udphdr.udp_dport",
      :source_port => {
        :tcp => "tcphdr.tcp_sport",
        :udp => "udphdr.udp_sport"
      },
      :destination_port => {
        :tcp => "tcphdr.tcp_dport",
        :udp => "udphdr.udp_dport"
      },
      :classification => "event.classification_id",
      :sensor => "event.sid",
      :user => "event.user_id",
      :payload => "data.data_payload",
      :start_time => "event.timestamp",
      :end_time => "event.timestamp",
      :sig_sid => "signature.sig_sid",
      :sig_gid => "signature.sig_gid"
    }

    OPERATOR = {
      :is => "= ?",
      :is_not => "!= ?",
      :contains => "LIKE ?",
      :contains_not => 'NOT LIKE ?',
      :gte => ">= ?",
      :lte => "<= ?",
      :lt => "< ?",
      :gt => "> ?",
      :in => "IN",
      :not_in => "NOT IN (?)",
      :notnull => "IS NOT NULL",
      :isnull => "IS NULL",
      :between => "BETWEEN ? AND ?"
    }

    COLUMN_NAME = {
      :tcp_source_port => "TCP Source Port",
      :udp_source_port => "UDP Source Port",
      :destination_ip => "Destination Address",
      :source_ip => "Source Address",
      :tcp_destination_port => "TCP Destination Port",
      :udp_destination_port => "UDP Destination Port",
      :classification => "Classification",
      :signature => "Signature",
      :signature_name => "Signature Name",
      :sensor => "Sensor",
      :start_time => "Start Time",
      :end_time => "End Time",
      :payload => "Payload",
      :severity => "Severity",
      :sig_sid => "Signature ID",
      :sig_gid => "Signature Group ID"
    }

    EXAMPLE = {"0"=>{"column"=>"source_port", "operator"=>"is", "value"=>"80"}, "1"=>{"column"=>"destination_ip", "operator"=>"is", "value"=>"10.0.1.1"}, "2"=>{"column"=>"signature", "operator"=>"is", "value"=>"1"}, "3"=>{"column"=>"classification", "operator"=>"is", "value"=>"1"}, "4"=>{"column"=>"sensor", "operator"=>"is", "value"=>"1"}, "5"=>{"column"=>"start_time", "operator"=>"gte", "value"=>"2012/02/21 12:05:17"}}

    OR = lambda do |data|
      "select a.* from (#{data}) a"
    end

    AND = lambda do |data|
      "select event.* from events_with_join as event #{data}"
    end

    DO_OR = lambda do |data|
      return "select event.* from events_with_join as event #{data} where 1 = 0 or " if data
      "select event.* from events_with_join as event where 1 = 0 or "
    end

    TCP = "inner join tcphdr on event.sid = tcphdr.sid and event.cid = tcphdr.cid "

    UDP = "inner join udphdr on event.sid = udphdr.sid and event.cid = udphdr.cid "

    SIGNATURE = "inner join signature on event.signature = signature.sig_id "

    SENSOR = "inner join sensor on event.sid = sensor.sid "

    IP = "inner join iphdr on event.sid = iphdr.sid and event.cid = iphdr.cid "

    PAYLOAD = "inner join data on event.sid = data.sid and event.cid = data.cid "

    DEFAULT_PROCESS = lambda do |data|
      data
    end

    BUILD = {
      :or => {
        :event => { 
          :sql => DO_OR.call(false),
          :process => DEFAULT_PROCESS
        },
        :tcp => {
          :sql => DO_OR.call(TCP),
          :process => DEFAULT_PROCESS,
        },
        :udp => { 
          :sql => DO_OR.call(UDP),
          :process => DEFAULT_PROCESS
        },
        :signature => { 
          :sql => DO_OR.call(SIGNATURE),
          :process => DEFAULT_PROCESS
        },
        :sensor => { 
          :sql => DO_OR.call(SENSOR),
          :process => DEFAULT_PROCESS
        },
        :payload => { 
          :sql => DO_OR.call(PAYLOAD),
          :process => lambda do |data|
            convert_values = []
            data.each do |x|
              hex = ""
              x.to_s.each_char { |x| hex += x.unpack('H*')[0] }
              convert_values.push("%#{hex}%")
            end
            convert_values
          end
        },
        :ip => { 
          :sql => DO_OR.call(IP),
          :process => lambda do |data|
            tmp = []
            data.each do |ip|
              tmp.push(IPAddr.new(ip.to_s).to_i)
            end
            tmp
          end
        }
      },
      :and => {
        :event => { 
          :sql => "",
          :process => DEFAULT_PROCESS
        },
        :tcp => { 
          :sql => TCP,
          :process => DEFAULT_PROCESS
        },
        :udp => {
          :sql => UDP,
          :process => DEFAULT_PROCESS
        },
        :signature => {
          :sql => SIGNATURE,
          :process => DEFAULT_PROCESS
        },
        :sensor => {
          :sql => SENSOR,
          :process => DEFAULT_PROCESS
        },
        :payload => {
          :sql => PAYLOAD,
          :process => lambda do |data|
            convert_values = []
            data.each do |x|
              hex = ""
              x.to_s.each_char { |x| hex += x.unpack('H*')[0] }
              convert_values.push("%#{hex}%")
            end
            convert_values
          end
        },
        :ip => {
          :sql => IP,
          :process => lambda do |data|
            tmp = []
            data.each do |ip|
              if ip.is_a?(Array)
                ip.each do |address|
                  tmp.push(IPAddr.new(address.to_s).to_i)
                end
              else
                tmp.push(IPAddr.new(ip.to_s).to_i)
              end
            end
            tmp
          end
        }
      }
    }

    MAP = {
      :source_port => [:tcp, :udp],
      :tcp_source_port => :tcp,
      :udp_source_port => :udp,
      :udp_destination_port => :udp,
      :tcp_destination_port => :tcp,
      :source_ip => :ip,
      :destination_port => [:tcp, :udp],
      :destination_ip => :ip,
      :signature_name => :signature,
      :severity => :signature,
      :signature => :event,
      :payload => :payload,
      :start_time => :event,
      :end_time => :event,
      :classification => :event,
      :user => :event,
      :sensor => :event,
      :sensor_name => :sensor,
      :sig_sid => :signature,
      :sig_gid => :signature,
      :has_note => :event
    }

    def self.data_column(column, value)

      case column.to_sym
      when :sensor
        Sensor.get(value.to_i).name
      when :signature
        if /^\d+-\d+$/.match(value)
          sig_gid, sig_sid = value.split("-")
          Signature.first(sig_gid: sig_gid, sig_sid: sig_sid).sig_name
        else
          Signature.get(value.to_i).sig_name
        end
      when :severity
        Severity.get(value.to_i).name
      when :classification
        Classification.get(value.to_i).name
      else
        value
      end

    end

    def self.joins
      [
        :event,
        :signature,
        :payload, 
        :ip, 
        :sensor,
        :tcp, 
        :udp
      ]
    end

    def self.all(&block)
      all = []
      self.joins.each do |x|
        block.call(x) if block
        all.push instance_variable_get("@" + x.to_s)
      end
      all
    end

    def self.all_quick_search(&block)
      all = []
      self.joins.each do |x|
        block.call(x) if block
        all.push instance_variable_get("@quick_search_" + x.to_s)
      end
      all
    end

    def self.build(matchall, page=true, params=EXAMPLE, quick_search_params={})
      self.joins.each do |x|
        instance_variable_set("@" + x.to_s, [])
        instance_variable_set("@" + x.to_s + "_value", [])
      end

      unless quick_search_params.blank?

        self.joins.each do |x|
          instance_variable_set("@quick_search_" + x.to_s, [])
          instance_variable_set("@quick_search_" + x.to_s + "_value", [])
        end

      end

      @type = if matchall === "true"
        :and
      else
        :or
      end

      @params = params
      @quick_search_params = quick_search_params

      self.build_logic
      self.perform(page)
    end

    def self.perform(page)
      sql = []
      values = []
      quick_search_values = [] # clauses for quick search
      quick_search_values_2 = [] # values for quick search

      if @type.to_sym == :or
        join_string = " OR "
        sql_join_string = " UNION "
        pack = OR
      else
        join_string = " AND "
        sql_join_string = " "
        pack = AND
        and_values = []
      end

      self.all do |x|

        k = instance_variable_get("@" + x.to_s)
        v = instance_variable_get("@" + x.to_s + "_value")

        unless k.empty?
          if @type == :or
            sql.push(BUILD[@type][x.to_sym][:sql] + "(#{k.join(join_string)})")
            values.push(BUILD[@type][x.to_sym][:process].call(v)).flatten!
          else
            sql.push(BUILD[@type][x.to_sym][:sql])
            and_values.push("(#{k.join(join_string)})")
            values.push(BUILD[@type][x.to_sym][:process].call(v)).flatten!
          end
        end
      end

      unless @quick_search_params.blank?

        self.all_quick_search do |x|

          k = instance_variable_get("@quick_search_" + x.to_s)
          v = instance_variable_get("@quick_search_" + x.to_s + "_value")

          unless k.empty?
            sql.push(BUILD[@type][x.to_sym][:sql]) if instance_variable_get("@" + x.to_s).empty?
            quick_search_values.push("(#{k.join(' OR ')})")
            quick_search_values_2.push(BUILD[@type][x.to_sym][:process].call(v)).flatten!
          end

        end

      end

      if @type == :and
        sql = ["#{sql.join} where #{and_values.join(join_string)}"]
      end

      if quick_search_values.present? and and_values.present?
        sql[0] += " AND (#{quick_search_values.join(' OR ')})"
      elsif quick_search_values.present?
        sql[0] += " (#{quick_search_values.join(' OR ')})"
      end

      total_sql = []

      count = ["select count(*) from (#{pack.call(sql.join(sql_join_string))}) a"]

      dd = if page
             pack.call(sql.join(sql_join_string)) + " LIMIT ? OFFSET ?"
           else
             pack.call(sql.join(sql_join_string))
           end

      total_sql.push(dd)
      total_sql.push(values.flatten).flatten!
      total_sql.push(quick_search_values_2.flatten).flatten!
      count.push(values.flatten).flatten!
      count.push(quick_search_values_2.flatten).flatten!

      p [total_sql, count]

      [total_sql, count]
    end

    def self.build_logic
      @params.each do |k,v|

        column = (v['column'] or v[:column]).to_sym
        operator = (v['operator'] or v[:operator]).to_sym
        value = (v['value'] or v[:value])

        enabled = if (v.has_key?('enabled') or v.has_key?(:enabled))
          case (v['enabled'] or v[:enabled]).class.to_s
          when "TrueClass"
            true
          when "FalseClass"
            false
          when "String"
            (v['enabled'] or v[:enabled]) === "false" ? false : true
          else
            false
          end
        else
          (column && operator && value) ? true : false
        end

        next unless enabled

        if MAP.has_key?(column.to_sym)
          map_value = MAP[column.to_sym]

          if map_value.is_a?(Array)

            map_value.each do |x|

              if [:in].include?(operator) and [:signature_name].include?(column)
                tmp_sql = "#{COLUMN[column][x]} #{OPERATOR[operator]} ("
                value.split(', ').each do |v|
                  tmp_sql << "'#{v}',"
                end
                tmp_sql = tmp_sql[0,-2] + ")"
              elsif [:in].include?(operator)
                tmp_sql = "#{COLUMN[column][x]} #{OPERATOR[operator]} (#{value})"
              else  
                tmp_sql = "#{COLUMN[column][x]} #{OPERATOR[operator]}"
              end
              
              instance_variable_get("@" + x.to_s).push(tmp_sql)
              unless [:isnull, :notnull].include?(operator) or [:in].include?(operator)
                instance_variable_get("@" + x.to_s + "_value").push(value)
              end
            end

          else

            if [:in].include?(operator) and [:signature_name].include?(column)
              tmp_sql = "#{COLUMN[column]} #{OPERATOR[operator]} ("
              value.split(', ').each do |v|
                tmp_sql << "'#{v}',"
              end
              tmp_sql = tmp_sql[0..-2] + ")"
            elsif [:in].include?(operator)
              tmp_sql = "#{COLUMN[column]} #{OPERATOR[operator]} (#{value})"
            else
              tmp_sql = "#{COLUMN[column]} #{OPERATOR[operator]}"
            end
            instance_variable_get("@" + map_value.to_s).push(tmp_sql)
            unless [:isnull, :notnull].include?(operator) or [:in].include?(operator)
              instance_variable_get("@" + map_value.to_s + "_value").push(value)
            end

          end

        end
      end

      @quick_search_params.each do |k, v|

        column = (v['column'] or v[:column]).to_sym
        operator = (v['operator'] or v[:operator]).to_sym
        value = (v['value'] or v[:value])

        map_value = MAP[column.to_sym]
        tmp_sql = "#{COLUMN[column]} #{OPERATOR[operator]}"
        
        instance_variable_get("@quick_search_" + map_value.to_s).push(tmp_sql)
        unless [:isnull].include?(operator)
          instance_variable_get("@quick_search_" + map_value.to_s + "_value").push(value)
        end

      end

    end

    def self.json
      ability = Ability.new(User.current_user)

      @signatures      ||= Signature.all(:fields => [:sig_name, :sig_sid, :sig_gid], :unique => true, :order => :sig_name)
      @classifications ||= Classification.all(:fields => [:name, :id], :order => :name)
      @users           ||= User.all(:fields => [:name, :id], :order => :name)
      @sensors         ||= Sensor.all(:fields => [:name, :sid], :sid.not => 1, :domain => true, :order => :name).select{|s| ability.can?(:read, s)}
      @severities      ||= Severity.all(:fields => [:name, :sig_id], :order => :id.desc)

      @json ||= {
        :operators => {
          :more_text_input => [
            {
              :id => :is,
              :value => "is"
            },
            {
              :id => :is_not,
              :value => "is not"
            },
            {
              :id => :contains,
              :value => "contains"
            },
            {
              :id => :contains_not,
              :value => "does not contain"
            }
          ],
          :text_input => [
            {
              :id => :is,
              :value => "is"
            },
            {
              :id => :is_not,
              :value => "is not"
            }
          ],
          :datetime => [
            {
              :id => :is,
              :value => "is"
            },
            {
              :id => :is_not,
              :value => "is not"
            },
            {
              :id => :contains,
              :value => "contains"
            },
            {
              :id => :contains_not,
              :value => "does not contain"
            },
            {
              :id => :gt,
              :value => "greater than"
            },
            {
              :id => :gte,
              :value => "greater than or equal to"
            },
            {
              :id => :lt,
              :value => "less than"
            },
            {
              :id => :lte,
              :value => "less than or equal to"
            }
          ],
          :select_with_null => [
            {
              :id => :is,
              :value => "is"
            },
            {
              :id => :is_not,
              :value => "is not"
            },
            {
              :id => :isnull,
              :value => "is null"
            },
            {
              :id => :notnull,
              :value => "is not null"
            }
          ]
        },
        :columns => [
          {
            :value => "Classification",
            :id => :classification,
            :type => :select_with_null
          },
          {
            :value => "Classified By",
            :id => :user,
            :type => :select
          },
          {
            :value => "Destination Address",
            :id => :destination_ip,
            :type => :text_input
          },
          {
            :value => "End Time",
            :id => :end_time,
            :type => :datetime
          },
          {
            :value => "Payload",
            :id => :payload,
            :type => :text_input
          },
          {
            :value => "Start Time",
            :id => :start_time,
            :type => :datetime
          },
          {
            :value => "Sensor",
            :id => :sensor,
            :type => :select
          },
          {
            :value => "Severity",
            :id => :severity,
            :type => :select
          },
          {
            :value => "Signature",
            :id => :signature,
            :type => :select
          },
          {
            :value => "Signature ID",
            :id => :sig_sid,
            :type => :text_input
          },
          {
            :value => "Signature Name",
            :id => :signature_name,
            :type => :text_input
          },
          {
            :value => "Signature Group ID",
            :id => :sig_gid,
            :type => :text_input
          },
          {
            :value => "Source Address",
            :id => :source_ip,
            :type => :text_input
          },
          {
            :value => "TCP Destination Port",
            :id => :tcp_destination_port,
            :type => :text_input
          },
          {
            :value => "TCP Source Port",
            :id => :tcp_source_port,
            :type => :text_input
          },
          {
            :value => "UDP Destination Port",
            :id => :udp_destination_port,
            :type => :text_input
          },
          {
            :value => "UDP Source Port",
            :id => :udp_source_port,
            :type => :text_input
          }                    
          # {
            # :value => "Protocol",
            # :id => :protocol,
            # :type => :select
          # }
        ],
        :protocol => {
          :value => [
            {
              :id => :tcp,
              :value => "TCP"
            },
            {
              :id => :udp,
              :value => "UDP"
            },
            {
              :id => :icmp,
              :value => "ICMP"
            }
          ]
        },
        :has_note => {
          :value => [
            {
              :id => 1,
              :value => "Yes"
            },
            {
              :id => 0,
              :value => "No"
            }
          ]
        },
        :classifications => {
          :type => :dropdown,
          :value => @classifications.collect do |x|
            {
              :id => x.id,
              :value => x.name
            }
          end
        },
        :severities => {
          :type => :dropdown,
          :value => @severities.collect do |x|
            {
              :id => x.sig_id,
              :value => x.name
            }
          end
        },
        :signatures => {
          :type => :dropdown,
          :value => @signatures.collect do |x|
            {
              :id => "#{x.sig_gid}-#{x.sig_sid}",
              :value => "#{x.sig_name} (gid:#{x.sig_gid}; sid:#{x.sig_sid})"
            }
          end
        },
        :users => {
          :type => :dropdown,
          :value => @users.collect do |x|
            {
              :id => x.id,
              :value => x.name
            }
          end
        },
        :sensors => {
          :type => :dropdown,
          :value => @sensors.collect do |x|
            {
              :id => x.sid,
              :value => (x.virtual_sensor? ? x.name : "#{x.name.upcase} (domain)")
            }
          end
        }
      }

      @json.to_json.html_safe
    end

  end # Search
end # Snorby