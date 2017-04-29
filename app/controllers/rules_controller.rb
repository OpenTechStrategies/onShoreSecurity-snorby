class RulesController < ApplicationController

  respond_to :html, :xml, :json, :js, :csv

  COMPILED_RULES = "compiled_rules"
  LISTING_RULES  = "rules"
  PENDING_RULES  = "pending_rules"

  before_filter :check_sensor_dbversion_update
  skip_before_filter :authenticate_user!, :only => [ :active_rules, :preprocessors_rules, :classifications ]

  before_filter(:except => [ :show, :rollback, :active_rules, :preprocessors_rules, :sorty_rules, :thresholds, :classifications ]) do |c|
    @sensor = nil
    find_sensor if !params[:sensor_id].nil? and params[:sensor_id]!="0"
  end
  before_filter :sorty_rules, :only => [ :index, :update_rule_category, :update_rule_group, :update_rule_family, :update_rule_details, :update_rule_count]
  before_filter :update_rule_property, :only => [ :update_rule_action, :update_rule_overwrite, :update_rule_favorite  ]

  before_filter(:only => [:active_rules, :preprocessors_rules, :thresholds, :classifications]) do |c|
    authenticate_user! unless c.request.format.text?
    find_sensor unless c.request.format.text?
  end

  def index
    @compilation = RuleCompilation.get(params[:compilation_id]) unless params[:compilation_id].nil?
    @filters = (SavedRuleFilter.all(:user_id => @current_user.id, :limit => 5) | SavedRuleFilter.all(:public => true, :limit => 5, :user_id.not => @current_user.id)).all(:order => :title)
  end

  def show
    if params["rule_id"].nil? && params["rev"].nil?
      @rule = Rule.get(params["id"].to_i) unless params["id"].nil?
    else
      @rule = Rule.last(:rule_id=>params["id"].to_i, :gid=>params["gid"].to_i, :rev=>params["rev"].to_i)
    end

    respond_to do |format|
      format.html { render :layout => false }
    end
  end

  def view
    @rule = Rule.last(:rule_id => params[:rule_id], :gid => params[:gid], :dbversion_id => RuleDbversion.active.id)
    @rule = Rule.last(:rule_id => params[:rule_id], :gid => params[:gid]) if @rule.nil?
  end

  def search
    @sensor_id = params[:sensor_id]
    @rulestype = (params[:rule_type] or LISTING_RULES)

    @filter = Hash.new
    items = Hash.new
    index = 0

    unless params[:new_filter].present?
      session[:rule_filter].each do |k, v|
        v.each do |key, value|
          items[index] = {:column => k.to_s, :operator => value[:operator], :value => key.to_s, :enabled => true}
          index += 1
        end
      end
    end

    @filter = {:match_all => false, :items => items} unless items.blank?

  end

  def results

    if params.has_key?(:search) && !params[:search].blank?

      if params[:search].is_a?(String)
        @value ||= JSON.parse(params[:search])
        params[:search] = @value
      end

      session[:rule_filter] = {}

      enabled_count = 0
      for item in params[:search] do
        x = item.last
        enabled = (x['enabled'] or x[:enabled]).to_s

        if !enabled.blank?
          enabled_count += 1 if enabled.to_s === "true"
        else
          enabled_count += 1 
        end
      end

      if enabled_count == 0
        redirect_to :back, :flash => {:error => "There was a problem parsing the search rules."}
      end

      params[:search].each do |key, value|

        next if !value[:enabled]

        if session[:rule_filter][value[:column].to_sym] and session[:rule_filter][value[:column].to_sym][value[:value]]
          session[:rule_filter][value[:column].to_sym][value[:value]] = {:operator => value[:operator]}
        elsif session[:rule_filter][value[:column].to_sym]
          session[:rule_filter][value[:column].to_sym].merge! ({value[:value] => {:operator => value[:operator]}})
        elsif session[:rule_filter]
          session[:rule_filter].merge!({value[:column].to_sym => {value[:value] => {:operator => value[:operator]}}})
        end

      end

      redirect_to sensor_rules_path(:sensor_id => params[:sensor_id])

    elsif params.has_key?(:msg) && !params[:msg].blank?

      redirect_to sensor_rules_path(:sensor_id => params[:sensor_id], :msg => params[:msg])

    end

  end

  # Method used when the category is showed in the index view. Partial Method
  def update_rule_category
    respond_to do |format|
      format.js
    end
  end

  def update_rule_group
    respond_to do |format|
      format.js
    end
  end

  def update_rule_family
    respond_to do |format|
      format.js
    end
  end

  def update_rule_details
    
    @rule              = Rule.get(params["rule_id"].to_i) unless params[:rule_id].nil?
    @rule_references   = @rule.rule_references unless @rule.nil?
    @rule_policies     = @rule.rule_policies unless @rule.nil?
    @rule_flowbits     = @rule.rule_flowbits unless @rule.nil?
    if @sensor.nil?
      @rule_compilations = RuleCompilation.all(:id=>0)
    else
      @rule_compilations = @rule.compilations.all(:order => :timestamp.desc, :limit => 10, :sensor => @sensor.parents) unless @rule.nil?
      @suppress_rules    = @sensor.suppress_events_rules.select {|x| x.sig_sid==@rule.rule_id and x.sig_gid == @rule.gid}
      @limit_rules       = @sensor.limit_events_rules.select {|x| x.sig_sid==@rule.rule_id and x.sig_gid == @rule.gid}
    end

    respond_to do |format|
      format.js
    end
  end

  def update_rule_count
    render :text => "#{@rules.count} Rules"
  end

  def update_rule_action
    @rules = update_action_for_rules(@action, @rules, @sensor.pending_rules, @sensor.last_rules)
    respond_to :js
  end

  def update_rule_overwrite
    @allow_overwrite  = (params[:allow_overwrite] == "true" || params[:allow_overwrite] == "1" || params[:allow_overwrite]==true)
    @rules = update_allow_overwrite_for_rules(@allow_overwrite, @rules, @sensor.pending_rules, @sensor.last_rules)
    respond_to do |format|
      format.js
    end
  end

  def update_rule_favorite
    @create_favorite  = (params[:create_favorite] == "true" || params[:create_favorite] == "1" || params[:create_favorite]==true)
    @rules = update_favorite_for_rules(@create_favorite, @rules)
    respond_to do |format|
      format.js
    end
  end


  def update_rules_action
    sorty_rules(false, false, false)
    
    @selected_categories = params[:selected_categories] if params[:selected_categories].present?
    @selected_groups     = params[:selected_groups]     if params[:selected_groups].present?
    @selected_families   = params[:selected_families]   if params[:selected_families].present?
    @selected_rules      = params[:selected_rules]      if params[:selected_rules].present?

    tmp_rules = Rule.all(:id => 0)
    tmp_rules = @rules.all(:category4_id => params[:selected_categories]) if params[:selected_categories].present? and params[:selected_categories].class==Array
    tmp_rules = (tmp_rules | @rules.all(:category1_id => params[:selected_groups])) if params[:selected_groups].present? and params[:selected_groups].class==Array
    tmp_rules = (tmp_rules | @rules.all(:category3_id => params[:selected_families])) if params[:selected_families].present? and params[:selected_families].class==Array
    tmp_rules = (tmp_rules | @rules.all(:id => params[:selected_rules])) if params[:selected_rules].present? and params[:selected_rules].class==Array
    tmp_rules = (tmp_rules & @sensor.last_rules.rule) if @action.inherited?

    #Actualizamos la variable rules con las reglas modificadas
    @rules = update_action_for_rules(@action, tmp_rules, @sensor.pending_rules, @sensor.last_rules)
    respond_to :js    
  end

  def compile_rules
    if Setting.find(:flowbits_dependencies)
      # Check only 4 times the check_warnings method
      count = 4
      while @sensor.check_warnings.present? and count > 0 do
        @sensor.check_warnings.each do |warning|
          search = {:rule_flowbits => RuleFlowbit.all(:state => FlowbitState.first(:name => warning), 
                                                      :flowbit => Flowbit.first(:name => 'set')), 
                                                      :fields => [:id], 
                                                      :dbversion_id => @sensor.dbversion_id,
                                                      :id.not => @sensor.pending_rules.map(&:rule_id)
                    }

          if !Setting.find(:show_disabled_rules)
            search.merge!(:default_enabled => true)
          end

          num_rules = 0

          Rule.all(search).each do |rule|
            SensorRule.create(:sensor => @sensor, :rule => rule, :action => RuleAction.first(:name => 'alert'), :user => User.current_user)
            num_rules += 1
          end

          @sensor.update(:num_pending_rules => @sensor.num_pending_rules + num_rules)
        end
        count -= 1
      end
    end
    render :layout => false
  end

  def create_compile
    unless @sensor.compiling or @sensor.all_childs.select{|s| s.compiling}.size > 0
      Delayed::Job.enqueue(Snorby::Jobs::CompilationJob.new(@sensor.sid, User.current_user.id, params[:compilation][:name], true, false, true),
                          :priority => 1,
                          :run_at => Time.now + 5.seconds)
    end
  end

  def pending_rules
    sorty_rules(false, true)
    @rulestype = PENDING_RULES
    render :index
  end

  # Get last compiled rules for the sensor indicated
  def active_rules
    respond_to do |format|
      format.html{
        sorty_rules(true, false)
        @rulestype = COMPILED_RULES
        render :index
      }
      format.js{
        @sensor_rules = @sensor.last_compiled_rules
        @actions = RuleAction.all
        @rulestype = COMPILED_RULES
        @sensor_rules = @sensor_rules.page(params[:page].to_i, :per_page => User.current_user.per_page_count) unless @sensor_rules.blank?
      }
      format.text{
        @sensor = Sensor.first(:hostname => params[:sensor_name])
        @sensor_rules = @sensor.last_compiled_rules
        preprocessors_id = RuleCategory4.preprocessors.id
        @sensor_rules = @sensor_rules.select{|x| x.rule.category4_id != preprocessors_id} unless @sensor_rules.blank?
        @rulestype = COMPILED_RULES
      }
      format.csv{
        @sensor_rules = @sensor.last_compiled_rules
        export_csv(@sensor.name, @sensor_rules)
      }
    end
  end

  def preprocessors_rules
    respond_to do |format|
      format.text{
        @sensor = Sensor.first(:hostname => params[:sensor_name])
        @sensor_rules = @sensor.last_compiled_rules
        preprocessors_id = RuleCategory4.preprocessors.id
        @sensor_rules = @sensor_rules.select{|x| x.rule.category4_id == preprocessors_id} unless @sensor_rules.blank?
        @rulestype = "preprocessors_rules"
      }
    end
  end

  def thresholds
    @sensor = Sensor.first(:hostname => params[:sensor_name]) unless params[:sensor_name].nil?
    @event_filterings = @sensor.nil? ? [] : @sensor.event_filterings
  end

  def classifications
    @sensor = Sensor.first(:hostname => params[:sensor_name]) unless params[:sensor_name].nil?
    @classifications = @sensor.nil? ? [] : @sensor.last_compiled_rules.rule.classtype.all(:order => :name)
  end

  def reset_rules
    unless @sensor.nil?
      @sensor.reset_rules
    end
    redirect_to sensor_rules_path(@sensor.sid)
  end

  def discard_pending_rules
    unless @sensor.nil?
      @sensor.discard_pending_rules
    end
    redirect_to sensor_rules_path(@sensor.sid)
  end
  
  def compilations
    if @sensor.last_compilation.present?
      @compilations = @sensor.sensorRules.compilation.all(:order => [:timestamp.desc])
    else
      @compilations = []
    end

    @compilations = @compilations.all.page(params[:page].to_i, :per_page => 10)
    
    render :layout => false
  end
  
  def rollback
    @sensor = Sensor.get(params[:sensor][:sid])
    Delayed::Job.enqueue(Snorby::Jobs::RollbackJob.new(@sensor.sid, params[:compilation], User.current_user.id, true),
                        :priority => 1,
                        :run_at => Time.now + 5.seconds)
    redirect_to sensor_rules_path(@sensor.sid, :compilation_id => params[:compilation])
  end

  def import
    render :layout => false
  end

  def import_file

    content_file = params[:sensor][:csv_file]

    lines = 0

    file = File.open(content_file.tempfile)
    file.each_line do |line|
      action, rule_id, gid = line.gsub(/[\n]+/, "").split(",")
      lines += @sensor.override_pending_rule(rule_id.to_i, gid.to_i, action)
    end
    @sensor.update(:num_pending_rules => @sensor.pending_rules.size)
    flash[:notice] = "Successfully imported. #{lines} rules added."
    redirect_to pending_rules_sensor_rules_path(@sensor)

  end

  def add_filter
  
  end

  def del_filter
    
    values = params[:values]
    sensor = Sensor.get(params[:id])

    if params[:value].to_s == "all"
      session[:rule_filter] = {}
    else
    
      if values.nil? or !values.respond_to?('each')
        values=[]
      end

      values << params[:value] unless params[:value].nil?

      values.each do |val|
        if session[:rule_filter][params[:column].to_sym] and session[:rule_filter][params[:column].to_sym][val]
          if session[:rule_filter][params[:column].to_sym].count > 1
            session[:rule_filter][params[:column].to_sym].delete(val)
          else
            session[:rule_filter].delete(params[:column].to_sym)
          end
        elsif session[:rule_filter][params[:column].to_sym]
          session[:rule_filter][params[:column].to_sym].merge! ({ val => { :operator => "not" } })
        else
          session[:rule_filter].merge! ({ params[:column].to_sym => { val => { :operator => "not" } } })
        end
      end
    end

    redirect_to sensor_rules_path(:sensor_id => sensor.sid)

  end

  protected
    def update_favorite_for_rules(create_favorite, rules)
      rules_deleted = []
      RuleFavorite.transaction do |t|
        begin
          if create_favorite
            (rules or []).each do |r|
              if !r.modify_favorite(create_favorite)
                rules_deleted << r.id
              end
            end
          else
            RuleFavorite.all(:rule_id => rules.map(&:rule_id), :user => User.current_user).destroy!
          end
        rescue DataObjects::Error => e
          t.rollback
        end
      end
      rules = rules.all(:id.not => rules_deleted) if rules_deleted.present?
      rules
    end

    def update_allow_overwrite_for_rules(allow_overwrite, rules, sr_pending_rules, sr_last_compilation)
      rules_deleted = []
      SensorRule.transaction do |t|
        begin
          (rules or []).each do |r|
            sr = sr_pending_rules.first(:rule => r)
            if sr.nil?
              sr = sr_last_compilation.first(:rule => r)
              if sr.nil?
                rules_deleted << r.id
              else
                if sr.inherited and !sr.allow_overwrite
                  rules_deleted << r.id
                else
                  @sensor.sensorRules.create(sr.attributes.merge(:id => nil, :compilation => nil, :allow_overwrite => allow_overwrite))
                end
              end
            else
              sr.update(:allow_overwrite => allow_overwrite)
            end
          end
          @sensor.update(:num_pending_rules => @sensor.pending_rules.size, :num_active_rules => @sensor.last_compiled_rules.size)
        rescue DataObjects::Error => e
          t.rollback
        end
      end

      rules.all(:id.not => rules_deleted)
    end

    def update_action_for_rules(action, rules, sr_pending_rules, sr_last_compilation)
      rules_deleted = []
      SensorRule.transaction do |t|
        begin
          (rules or []).each do |r|
            sr = nil
            sr = sr_pending_rules.first(:rule => r)
            if sr.nil?
              sr = sr_last_compilation.first(:rule => r)
              if sr.nil?
                if action.inherited?
                  rules_deleted << r.id
                else
                  sr = @sensor.sensorRules.create(:user => User.current_user, :rule => r)
                end
              else
                if sr.inherited
                  if sr.allow_overwrite
                    # heredada y permite modificacion creamos una nueva
                    sr = @sensor.sensorRules.create(:user => User.current_user, :rule => r, :allow_overwrite => true)
                  else
                    # heredada y no permite modificacion. Esta regla no se modifica
                    rules_deleted << r.id
                  end
                else
                  # No esta heredada pero puede que antes haya impuesto un valor del overwrite
                  sr = @sensor.sensorRules.create(:user => User.current_user, :rule => r, :allow_overwrite => sr.allow_overwrite)
                end
              end
            end

            unless sr.nil? 
              unless (sr.inherited and !sr.allow_overwrite)
                sr.update(:action => action)
              end
            end
          end

          @sensor.update(:num_pending_rules => @sensor.pending_rules.size)

        rescue DataObjects::Error => e
          t.rollback
        end
      end
      rules.all(:id.not => rules_deleted)
    end

    def find_sensor
      @sensor = Sensor.get!(params[:sensor_id])

      if !@sensor.domain
        raise DataMapper::ObjectNotFoundError
      end
      authorize! :manage, @sensor
    end

    def sorty_rules(force_compiled=false, force_pending=false, filter_action=true)

      if params.has_key?(:search) && !params[:search].blank?

        if params[:search].is_a?(String)
          @value ||= JSON.parse(params[:search])
          params[:search] = @value
        end

        session[:rule_filter] = {}

        enabled_count = 0
        for item in params[:search] do
          x = item.last
          enabled = (x['enabled'] or x[:enabled]).to_s

          if !enabled.blank?
            enabled_count += 1 if enabled.to_s === "true"
          else
            enabled_count += 1 
          end
        end

        if enabled_count == 0
          redirect_to :back, :flash => {:error => "There was a problem parsing the search rules."}
        end

        params[:search].each do |key, value|

          next if !value[:enabled]

          if session[:rule_filter][value[:column].to_sym] and session[:rule_filter][value[:column].to_sym][value[:value]]
            session[:rule_filter][value[:column].to_sym][value[:value]] = {:operator => value[:operator]}
          elsif session[:rule_filter][value[:column].to_sym]
            session[:rule_filter][value[:column].to_sym].merge! ({value[:value] => {:operator => value[:operator]}})
          elsif session[:rule_filter]
            session[:rule_filter].merge!({value[:column].to_sym => {value[:value] => {:operator => value[:operator]}}})
          end

        end

      end

      @show_disabled_rules = !Setting.find(:show_disabled_rules).nil?
      is_compiled_rules   = (params[COMPILED_RULES] == "true")
      is_pending_rules    = (params[PENDING_RULES] == "true")
      @actions             = RuleAction.all

      @show_disabled_rules = true if params[:disabled_rules].present?

      params.delete_if{|key, value| value.blank?}

      search = {}

      if ((params[:rule_type] == COMPILED_RULES || is_compiled_rules || force_compiled) and !@sensor.nil?)
        @rulestype  = COMPILED_RULES
        @last_rules = @sensor.last_compiled_rules
        @rules      = @last_rules.rule
      elsif ((params[:rule_type] == PENDING_RULES || is_pending_rules || force_pending) and !@sensor.nil?)
        @rulestype  = PENDING_RULES
        @last_rules = @sensor.pending_rules
        @rules      = @last_rules.rule
      else
        @rulestype   = LISTING_RULES
        @rules       = Rule

        if @sensor.nil?
          @last_rules = SensorRule.all(:id => 0)
          if params[:dbversion_id].present?
            search.merge!(:dbversion_id => params[:dbversion_id])
          else
            search.merge!(:dbversion_id => RuleDbversion.last(:completed=>true).id)
          end
        else
          if params[:compilation_id].nil?
            @last_rules = @sensor.last_rules
            search.merge!(:dbversion_id => @sensor.dbversion_id)
          else
            compilation = RuleCompilation.get(params[:compilation_id].to_i)
            if compilation.nil?
              @last_rules = @sensor.last_rules
              search.merge!(:dbversion_id => @sensor.dbversion_id)
            else
              @last_rules = @sensor.compiled_rules(params[:compilation_id].to_i)          
              compilation_rules = compilation.rules
              if compilation_rules.present?
                dbversion = compilation_rules.dbversion.first
                if dbversion.nil?
                  search.merge!(:dbversion_id => @sensor.dbversion_id)
                else
                  search.merge!(:dbversion_id => dbversion.id)
                end
              else
                search.merge!(:dbversion_id => @sensor.dbversion_id)
              end
            end
          end
        end
      end
      search.merge!(:fields => [:id])
      search.merge!(:default_enabled => true) unless @show_disabled_rules

      if params[:msg].present?
        @quick_search = params[:msg]
        search.merge!(:conditions   => ["rule LIKE ?", "%#{params[:msg].split.join('%')}%"])
      end

      #Sobre todas las reglas filtramos
      @action   = RuleAction.get(params[:action_id].to_i)      if params[:action_id].present?
      @category = RuleCategory4.get(params[:category_id].to_i) if params[:category_id].present?
      @group    = RuleCategory1.get(params[:group_id].to_i)    if params[:group_id].present?
      @family   = RuleCategory3.get(params[:family_id].to_i)   if params[:family_id].present?
      @rule     = Rule.get(params[:rule_id].to_i)              if params[:rule_id].present?

      if !@rule.nil?
        @rules    = Rule.all(:id => @rule.id)
        @category = @rule.category4
        @group    = @rule.category1
        @family   = @rule.category3
        @families = [@family]
      end

      session[:rule_filter].each do |k, v|

        next if [:favorite, :inherited].include? k.to_sym

        v.each do |key, value|

          if k.to_sym == :action_id
            
            rules_id_tmp = @last_rules.all(:action_id => key).map(&:rule_id)

            operator_tmp = value[:operator] == "is" ? :id : :id.not

            if search[operator_tmp]
              search[operator_tmp] = [search[operator_tmp]] unless search[operator_tmp].kind_of?(Array)
              search[operator_tmp] << rules_id_tmp
            else
              search[operator_tmp] = rules_id_tmp
            end

          elsif [:cve, :nessus, :bugtraq].include? k.to_sym

            operator_tmp = value[:operator] == "is" ? :url : :url.send(value[:operator])

            reference_id = case k.to_sym
            when :cve
              2
            when :bugtraq
              1
            when :nessus
              3
            end

            references = RuleRbreference.all(:reference_id => reference_id, :url.send(value[:operator]) => "%#{key.split.join('%')}%")

            if search[:rule_references]
              search[:rule_references] = [search[:rule_references]] unless search[:rule_references].kind_of?(Array)
              search[:rule_references] << references
            else
              search[:rule_references] = references
            end

          elsif k.to_sym == :policy_id

            operator_tmp = value[:operator] == "is" ? :rule_policies : :rule_policies.send(value[:operator])

            policies = RulePolicy.all(k => key)

            if search[operator_tmp]
              search[operator_tmp] = [search[operator_tmp]] unless search[operator_tmp].kind_of?(Array)
              search[operator_tmp] << policies
            else
              search[operator_tmp] = policies
            end

          elsif [:flowbit_id, :flowbit_state_id].include? k.to_sym

            operator_tmp = value[:operator] == "is" ? :rule_flowbits : :rule_flowbits.send(value[:operator])
            rule_flowbits = (k.to_sym == :flowbit_id ? RuleFlowbit.all(:flowbit_id => key) : RuleFlowbit.all(:state_id => key))

            if search[operator_tmp] and search[operator_tmp][k.to_sym]
              search[operator_tmp][k.to_sym] = [search[operator_tmp][k.to_sym]] unless search[operator_tmp].kind_of?(Array)
              search[operator_tmp][k.to_sym].concat rule_flowbits
            else
              search[operator_tmp] = {} unless search[operator_tmp]
              search[operator_tmp][k.to_sym] = rule_flowbits
            end

          elsif k.to_sym == :severity

            operator_tmp = value[:operator] == "is" ? :category2_id : :category2_id.send(value[:operator])
            categories_2 = Severity.get(key).classtypes.map(&:id)

            if search[operator_tmp]
              search[operator_tmp] = [search[operator_tmp]] unless search[operator_tmp].kind_of?(Array)
              search[operator_tmp] << categories_2
            else
              search[operator_tmp] = categories_2
            end            

          elsif search[k] and value[:operator] == "is"
            search[k] = [search[k]] unless search[k].kind_of?(Array)
            search[k] << normalize(k, key)
          elsif value[:operator] == "is"
            search[k] = normalize(k, key)            
          elsif search[k.send(value[:operator])]
            search[k.send(value[:operator])] = [search[k.send(value[:operator])]] unless search[k.send(value[:operator])].kind_of?(Array)
            search[k.send(value[:operator])] << normalize(k, key)
          else
            search[k.send(value[:operator])] = normalize(k, key)
          end
        end         
      end

      search.keys.select{|x| x.to_s =~ /^rule_flowbits/ or (x.is_a?(DataMapper::Query::Operator) and x.target == :rule_flowbits)}.each do |key|
        
        if search[key][:flowbit_id].present? and search[key][:flowbit_state_id].present?
          search[key] = search[key][:flowbit_id] & search[key][:flowbit_state_id]
        elsif search[key][:flowbit_id].present?
          search[key] = search[key][:flowbit_id]
        else
          search[key] = search[key][:flowbit_state_id]
        end

      end

      #Buscamos las reglas
      @rules = @rules.all(search) if search.present?
      @last_rules_rules = @last_rules.rule

      if session[:rule_filter] and session[:rule_filter][:favorite]
        @rules = (@rules & RuleFavorite.all(:user => User.current_user).rule.all(search)) if session[:rule_filter][:favorite]["1"]
        @rules = (@rules - RuleFavorite.all(:user => User.current_user).rule.all(search)) if session[:rule_filter][:favorite]["0"]
      end

      if session[:rule_filter] and session[:rule_filter][:inherited]
        @rules = (@rules & @last_rules.all(:inherited => true ).rules.all(search)) if session[:rule_filter][:inherited]["1"]
        @rules = (@rules & @last_rules.all(:inherited => false ).rules.all(search)) if session[:rule_filter][:inherited]["0"]
      end

      # Search when expanding categories, groups or families
      search_js = {}

      search_js.merge!(:category4_id  => @category.id) unless @category.nil?
      search_js.merge!(:category1_id  => @group.id) unless @group.nil?
      search_js.merge!(:category3_id  => @family.id) unless @family.nil?

      @rules = @rules.all(search_js) unless search_js.blank?

      if @category.nil?
        @categories = @rules.category4.all(:order => [:name.asc])
      else
        @categories = [@category]
        @groups = @rules.category1.all(:order => [:name.asc]) #Sólo una categoría
      end

      if @categories.size==1
        @category = @categories.first
        @groups   = @rules.category1.all(:order => [:name.asc])
        if @groups.size==1
          @group    = @groups.first
          @families = @rules.category3.all(:order => [:name.asc])
        end
      end

    end

    def update_rule_property
      sorty_rules(false, false, false)
      @group = nil
      if params[:group_id]
        @group = RuleCategory1.get(params[:group_id])
      end
      @family = nil
      if params[:family_id]
        @family = RuleCategory3.get(params[:family_id])
      end
    end

    def export_csv(sensor_name, sensor_rules)
      filename = I18n.l(Time.now, :format => :short) + "-" + sensor_name+".csv"
      content = sensor_rules.map{|sr| sr.action.name+","+sr.rule.rule_id.to_s+","+sr.rule.gid.to_s}.join("\n")
      send_data content, :filename => filename
    end

    def session_to_params

      params_aux = {}

      session[:rule_filter].each do |k, v|
        
        v.each do |key, value|
        
          if params_aux[k] and params_aux[k][value[:operator]]
            params_aux[k][value[:operator]] = [params_aux[k][value[:operator]]] unless params_aux[k][value[:operator]].kind_of?(Array)
            params_aux[k][value[:operator]] << key
          elsif params_aux[k]
            params_aux[k].merge!({value[:operator] => k})
          else
            params_aux[k] = {value[:operator] => key}
          end

        end

      end

      params_search = {}
      count = 0
      hash_tmp = {}

      params_aux.each do |k, v|
        v.each do |key, value|
          
          if key.to_sym == :is and value.is_a?(Array)
            params_search[count.to_s] = {"column" => k, "operator" => "in", "value" => value}
          elsif value.is_a?(Array)
            params_search[count.to_s] = {"column" => k, "operator" => key, "value" => value.first}

            value[1..value.length - 1].each do |s|
              count += 1
              hash_tmp[count.to_s] = {"column" => k, "operator" => key, "value" => s}
            end
          else
            params_search[count.to_s] = {"column" => k, "operator" => key, "value" => value}
          end
          
          count += 1
        end
      end

      params_search.merge!(hash_tmp)

      params_search

    end

    def normalize(column, value)

      val = value

      if column == :protocol and value == "none"
        val = nil
      end      

      val

    end

end
