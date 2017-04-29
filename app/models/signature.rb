require 'snorby/model/counter'

class Signature

  include DataMapper::Resource
  include Snorby::Model::Counter
  
  storage_names[:default] = "signature"

  #belongs_to :category, :parent_key => :sig_class_id, :child_key => :sig_class_id, :required => true

  has n, :events, :parent_key => :sig_id, :child_key => :sig_id, :constraint => :destroy
  
  has n, :notifications, :child_key => :sig_id, :parent_key => :sig_id
  
  belongs_to :severity, :child_key => :sig_priority, :parent_key => :sig_id
  
  #has n, :sig_references, :parent_key => :sig_rev, :child_key => [ :ref_seq ]

  property :sig_id, Serial, :key => true, :index => true

  property :sig_class_id, Integer, :index => true

  property :sig_name, Text
  
  property :sig_priority, Integer, :index => true
    
  property :sig_rev, Integer, :lazy => true
      
  property :sig_sid, Integer, :lazy => true

  property :sig_gid, Integer, :lazy => true

  property :events_count, Integer, :index => true, :default => 0

  #has n, :rules, :model => "Rule", :child_key => [:rule_id, :gid, :rev ], :parent_key => [:sig_id, :sig_gid, :sig_rev ], :constraint => :skip

  def severity_id
    sig_priority
  end
  
  def name
    
    rule = Rule.last(:rule_id=>sig_sid, :gid=>sig_gid, :rev=>sig_rev)

    if sig_name.start_with? "Snort Alert" and rule.present?
      return rule.msg
    else
      return sig_name
    end    
  
  end
  
  #
  #  
  # 
  def event_percentage(in_words=false, count=Event.count)
    begin
      if in_words
        "#{self.events_count}/#{count}"
      else
        "%.2f" % ((self.events_count.to_f / count.to_f) * 100).round(2)
      end

    rescue FloatDomainError
      0
    end
  end

  def self.sorty(params={})
    sort = params[:sort]
    direction = params[:direction]

    page = {
      :per_page => User.current_user.per_page_count
    }

    page.merge!(:order => sort.send(direction))

    page(params[:page].to_i, page)
  end

end
