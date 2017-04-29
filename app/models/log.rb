class Log
  
  include DataMapper::Resource
  
  property :id, Serial, :key => true
  
  property :model_name, String
  
  property :action, String
  
  property :model_id, String
  
  property :message, Text, :lazy => true
  
  timestamps :at
  
  belongs_to :user
  
  SORT = {
    :name       => "user",
    :model_name => "log",
    :action     => "log",
    :created_at => "log",
    :action     => "log"
  }
  
  def pretty_time
    return "#{created_at.strftime('%l:%M %p')}" if Date.today.to_date == created_at.to_date
    "#{created_at.strftime('%m/%d/%Y')}"
  end
  
  def object_name
    
    case model_name.to_sym
    when :Event
      obj = Event.find_by_ids(model_id).first
      return obj.signature.name unless obj.nil?
    when :Lookup
      obj = Lookup.get(model_id)
      return obj.title unless obj.nil?
    when :RoleSensor, :RoleUser
      obj = Role.get(model_id)
      return obj.name unless obj.nil?
    when :RuleDbversion
      obj = RuleDbversion.get(model_id)
      return obj.timestamp.strftime('%m/%d/%Y') unless obj.nil?
    when :AutoClassification
      return model_id
    else
      obj = eval(model_name).get(model_id)
      if obj.nil?
        "&nbsp;".html_safe
      else
        if obj.respond_to?"log_name"
          return obj.log_name
        elsif obj.respond_to?"name"
          return obj.name unless obj.name.blank?
        elsif obj.respond_to?"id"
          return obj.id 
        end
      end
    end    
    return "&nbsp;".html_safe
    
  end
  
  def model_name_translate
    case model_name.to_sym
    when :RoleSensor, :RoleUser
      "Role"
    when :RuleCompilation
      "Compilation"
    else
      model_name
    end
  end
  
  def self.sorty(params={})
    sort = params[:sort]
    direction = params[:direction]

    page = {
      :per_page => User.current_user.per_page_count
    }

    if SORT[sort].downcase == 'log'
      page.merge!(:order => sort.send(direction))
    else
      page.merge!(:order => [Log.send(SORT[sort].to_sym).send(sort).send(direction), :created_at.send(direction)],
                  :links => [Log.relationships[SORT[sort].to_s].inverse])
    end
    
    if params.has_key?(:search)
    
      params[:search].delete_if{|key, value| value.blank?}
      
      page.merge!({:user_id => params[:search][:user_id]}) unless params[:search][:user_id].blank?
      
      page.merge!({:model_name => params[:search][:resource]}) unless params[:search][:resource].blank?
      
      page.merge!({:action => params[:search][:action]}) unless params[:search][:action].blank?
      
      page.merge!({:message.like => "%#{params[:search][:text].split.join('%')}%"}) unless params[:search][:text].blank?

    end

    page(params[:page].to_i, page)
  end

end
