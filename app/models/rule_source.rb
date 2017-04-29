class RuleSource
  # Rule procedence source. When the script rules2rbIPS is executed it can downloads the rules 
  #     from different sources. This model will represent the procedence of that rule.

  include DataMapper::Resource
  
  property :id, Serial, :key => true, :index => true
  property :name, String, :length => 64, :required => true
  property :description, String, :length => 128
  property :timestamp, DateTime, :index => true
  property :md5, String, :length => 64
  property :protected, Boolean, :default => false
  property :enable, Boolean, :default => false
  property :has_code, Boolean, :default => false
  property :code, String, :length => 128
  property :tgzurl, String, :length => 128
  property :md5url, String, :length => 128
  property :regexp_category1_ignore, String, :length => 128
  property :regexp_category2_ignore, String, :length => 128
  property :regexp_category3_ignore, String, :length => 128
  property :search, Json, :default => ["rules", "preproc_rules", "so_rules"].to_json
  property :so_rules, Json, :default => [].to_json
  
  validates_uniqueness_of :name

  has n, :rules, :child_key => [ :source_id ], :constraint => :destroy
  has n, :dbversionSources, :child_key => [ :source_id ]
  has n, :dbversions, :model => 'RuleDbversion', :through => :dbversionSources, :via => :ruleDbversion

  
  audit :name, :description, :tgzurl, :md5url, :enable do |action|
    
    if User.current_user.present?
    
      log_attributes = {:model_name => self.class, :action => action, :model_id => self.id, :user => User.current_user}

      case action.to_sym
      when :create
        log_attributes.merge!({:message => "Created #{self.class} '#{self.name}'"})
      when :update
        log_attributes.merge!({:message => changes.collect {|prop, values|
                                                            "Changed #{prop.name} from '#{values[0]}' to '#{values[1]}'"
                                                          }.join(", ")
                              })
      when :destroy
        log_attributes.merge!({:message => "Destroyed #{self.class} '#{self.name}'"})
      end

      Log.new(log_attributes).save
      
    end

  end
  
  
  def full_tgzurl
    if has_code and code.present?
      self.tgzurl.gsub('$$code$$', code)
    else
      self.tgzurl
    end
  end

  def full_md5url
    if has_code and code.present?
      md5url.gsub('$$code$$', code)
    else
      md5url
    end
  end


end
