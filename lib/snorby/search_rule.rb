module Snorby
	module SearchRule
	
		COLUMN = {
			:action_id => 'action_id',
			:category1_id => 'category1_id',
      :category2_id => 'category2_id',
      :category4_id => 'category4_id',
			:favorite => 'favorite',
      :flowbit_id => 'flowbit_id',
      :flowbit_state_id => 'flowbit_state_id',
      :inherited => 'inherited',
      :is_modified => 'is_modified',
      :is_new => 'is_new',
      :policy_id => 'policy_id',
      :protocol => 'protocol',
      :source_id => 'source_id',
      :is_deprecated => 'is_deprecated',
      :rule => 'rule',
      :bugtraq => 'bugtraq',
      :nessus => 'nessus',
      :cve => 'cve',
      :severity => 'severity'
		}

		OPERATOR = {
      :is => "= ?",
      :not => "!= ?",
      :contains => "LIKE ?",
      :contains_not => 'NOT LIKE ?',
      :gte => ">= ?",
      :lte => "<= ?",
      :lt => "< ?",
      :gt => "> ?",
      :in => "IN",
      :not_in => "NOT IN (?)",
      :notnull => "NOT NULL ?",
      :isnull => "IS NULL",
      :between => "BETWEEN ? AND ?"
    }

		COLUMN_NAME = {
			:action_id => "Action State",
      :category1_id => "Group",
      :category2_id => "Classtype",
			:category4_id => "Category",
			:favorite => "Favorite",
      :flowbit_id => 'Flowbit',
      :flowbit_state_id => 'Flowbit State',
      :inherited => "Inherited",
      :is_modified => "Modified Rule",
      :is_new => "New Rule",
      :policy_id => "Policy",
      :protocol => 'Protocol',
      :source_id => 'Source',
      :is_deprecated => 'Deprecated Rule',
      :rule => 'Rule Message',
      :bugtraq => 'Bugtraq Reference',
      :nessus => 'Nessus Reference',
      :cvee => 'CVE Reference',
      :severity => 'Severity'

		}

		def self.json
			@actions        = RuleAction.all(:name.not => "inherited", :fields => [:name, :id], :order => :name)
			@categories     = RuleCategory4.all(:fields => [:name, :id], :order => :name)
			@flowbits       = Flowbit.all(:fields => [:name, :id], :order => :name)
      @flowbit_states = FlowbitState.all(:fields => [:name, :id], :order => :name)
      @groups         = RuleCategory1.all(:fields => [:name, :id], :order => :name)
      @policies       = Policy.all(:fields => [:name, :id], :order => :name)
      @protocols      = DataMapper::Collection::Rule.protocols.map{|x| [x,x.upcase]} << ["none", "None"]
      @sources        = RuleSource.all(:fields => [:name, :id], :order => :name)
      @classtypes     = RuleCategory2.all(:fields => [:name, :id], :order => :name, :dbversion_id => RuleDbversion.active.id)
      @severities     = Severity.all(:fields => [:name, :id], :order => :id.desc)

			@json ||= {
				:operators => {
					:text_input => [
						{
              :id => :is,
              :value => "is"
            },
            {
              :id => :not,
              :value => "is not"
            }
					],
          :boolean_input => [
            {:id => :is, :value => "is"}
          ]
				},
				:columns => [
					{
            :value => "Action State",
            :id => :action_id,
            :type => :select
          },
          {
            :value => "Bugtraq Reference",
            :id => :bugtraq,
            :type => :text_input
          },
          {
          	:value => "Category",
          	:id => :category4_id,
          	:type => :select
          },
          {
            :value => "Classtype",
            :id => :category2_id,
            :type => :select
          },
          {
            :value => "CVE Reference",
            :id => :cve,
            :type => :text_input
          },
          {
            :value => "Deprecated Rule",
            :id => :is_deprecated,
            :type => :boolean_input
          },
          {
            :value => "Favorite",
            :id => :favorite,
            :type => :boolean_input
          },
          {
            :value => 'Flowbit',
            :id => :flowbit_id,
            :type => :select
          },
          {
            :value => 'Flowbit State',
            :id => :flowbit_state_id,
            :type => :select
          },
          {
            :value => "Group",
            :id => :category1_id,
            :type => :select
          },
          {
            :value => 'Inherited',
            :id => :inherited,
            :type => :select
          },
          {
            :value => 'Modified Rule',
            :id => :is_modified,
            :type => :select
          },
          {
            :value => "Nessus Reference",
            :id => :nessus,
            :type => :text_input
          },
          {
            :value => 'New Rule',
            :id => :is_new,
            :type => :boolean_input
          },
          {
            :value => "Policy",
            :id => :policy_id,
            :type => :select
          },
          {
            :value => "Protocol",
            :id => :protocol,
            :type => :select
          },
          {
            :value => "Rule Message",
            :id => :rule,
            :type => :text_input
          },
          {
            :value => "Severity",
            :id => :severity,
            :type => :select
          },
          {
            :value => "Source",
            :id => :source_id,
            :type => :select
          }          
				],
				:action_id => {
          :type => :dropdown,
          :value => @actions.collect do |x|
            {
              :id => x.id,
              :value => x.name
            }
          end
        },
        :category2_id => {
          :type => :dropdown,
          :value => @classtypes.collect do |x|
            {
              :id => x.id,
              :value => x.name
            }
          end
        },
        :category4_id => {
        	:type => :dropdown,
        	:value => @categories.collect do |x|
        		{
        			:id => x.id,
        			:value => x.name
        		}
        	end
        },
        :severity => {
          :type => :dropdown,
          :value => @severities.collect do |x|
            {
              :id => x.id,
              :value => x.name
            }
          end
        },
        :favorite => {
        	:type => :dropdown,
        	:value => [{:id => "1", :value => "Yes"}, {:id => "0", :value => "No"}]
        },
        :flowbit_id => {
          :type => :dropdown,
          :value => @flowbits.collect do |x|
            {
              :id => x.id,
              :value => x.name
            }
          end
        },
        :flowbit_state_id => {
          :type => :dropdown,
          :value => @flowbit_states.collect do |x|
            {
              :id => x.id,
              :value => x.name
            }
          end
        },
        :inherited => {
          :type => :dropdown,
          :value => [{:id => "1", :value => "Yes"}, {:id => "0", :value => "No"}]
        },
        :is_modified => {
          :type => :dropdown,
          :value => [{:id => "1", :value => "Yes"}, {:id => "0", :value => "No"}]
        },
        :is_new => {
          :type => :dropdown,
          :value => [{:id => "1", :value => "Yes"}, {:id => "0", :value => "No"}]
        },
        :category1_id => {
          :type => :dropdown,
          :value => @groups.collect do |x|
            {
              :id => x.id,
              :value => x.name
            }
          end
        },
        :policy_id => {
          :type => :dropdown,
          :value => @policies.collect do |x|
            {
              :id => x.id,
              :value => x.name
            }
          end
        },
        :protocol => {
          :type => :dropdown,
          :value => @protocols.collect do |x|
            {
              :id => x[0],
              :value => x[1]
            }
          end
        },
        :source_id => {
          :type => :dropdown,
          :value => @sources.collect do |x|
            {
              :id => x.id,
              :value => x.name
            }
          end
        },
        :is_deprecated => {
          :type => :dropdown,
          :value => [{:id => "1", :value => "Yes"}, {:id => "0", :value => "No"}]
        }
			}

			@json.to_json.html_safe
		end

    def self.data_column(column, value)

      case column.to_sym
      when :action_id
        RuleAction.get(value.to_i).name
      when :category4_id
        RuleCategory4.get(value.to_i).name
      when :flowbit_id
        Flowbit.get(value.to_i).name
      when :flowbit_state_id
        FlowbitState.get(value.to_i).name
      when :category1_id
        RuleCategory1.get(value.to_i).name
      when :policy_id
        Policy.get(value.to_i).name
      when :source_id
        RuleSource.get(value.to_i).name
      when :category2_id
        RuleCategory2.get(value.to_i).name
      when :severity
        Severity.get(value.to_i).name
      when :favorite, :inherited
        value.to_i.zero? ? "No" : "Yes"
      else
        value
      end

    end

	end
end