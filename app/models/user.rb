require 'snorby/model/counter'
require 'net/ldap'
require 'devise_ldap_authenticatable'
require 'devise_ldap_authenticatable/strategy'
require 'dm-noisy-failures'
class User  
  include DataMapper::Resource
  include DataMapper::Validate
  include Paperclip::Resource
  include Snorby::Model::Counter
  include DataMapper::MassAssignmentSecurity
  include Devise::Models::LdapAuthenticatable
  cattr_accessor :current_user, :snorby_url, :current_json
  attr_protected :admin
  before :save do |get_ldap_email|
  def get_ldap_email
    self.email = Devise::LdapAdapter.get_ldap_param(self.email,"mail")
    self.name = Devise::LdapAdapter.get_ldap_param(self.email,"givenname")
  end
  end
  before :save do |sensor|
    if Snorby::CONFIG[:authentication_mode] == "ldap"
      if sensor.login.nil?
        errors.add "Login can't be blank"
        return false
      end
    else
      sensor.login = sensor.email
    end
  end

  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable, :lockable and :timeoutable
  if Snorby::CONFIG[:authentication_mode] == "cas"
    devise :cas_authenticatable, :registerable, :trackable, :timeoutable
    #property :email, String, :required => true, :unique => true
    property :login, String
  elsif Snorby::CONFIG[:authentication_mode] == "ldap"
    devise :ldap_authenticatable, :registerable, :rememberable, :trackable, :timeoutable, :validatable
    property :email, String
    property :login, String
  else
    devise :ldap_authenticatable, :database_authenticatable, :registerable, :rememberable, :trackable, :validatable, :timeoutable
    property :email, String,  :required => true, :unique => true
    property :login, String
  end

  attr_accessible :email, :login, :favorites_count, :rule_favorites_count, :accept_notes, :notes_count, :root_page, :per_page_count, :name, :timezone, :enabled, :encrypted_password, :password, :password_confirmation, :gravatar, :admin, :daily, :weekly, :monthly, :yearly, :last_daily_report_at, :last_weekly_report_at, :last_monthly_report_at, :last_email_report_at, :email_reports, :username

  attr_accessor :crop_x, :crop_y, :crop_w, :crop_h  
  property :favorites_count, Integer, :index => true, :default => 0
  property :rule_favorites_count, Integer, :index => true, :default => 0
  
  property :accept_notes, Integer, :default => 1
  
  property :notes_count, Integer, :index => true, :default => 0
  
  # Primary key of the user
  property :id, Serial, :key => true, :index => true
  
  property :encrypted_password, Text, :required => false
 
  property :root_page, String, :default => '/dashboard'

  property :daily, Boolean, :default => false

  property :weekly, Boolean, :default => false

  property :monthly, Boolean, :default => false

  property :yearly, Boolean, :default => false

  # Email of the user
  # 
  # property :email, String
  #
  property :avatar_file_name, String
  # 
  property :avatar_content_type, String
  # 
  property :avatar_file_size, Integer
  # 
  property :avatar_updated_at, DateTime
  
  property :per_page_count, Integer, :index => true, :default => 25
  
  # Full name of the user
  property :name, String, :lazy => true, :lazy => true
  
  # The timezone the user lives in
  property :timezone, String, :default => 'UTC', :lazy => true
  
  # Define if the user has administrative privileges
  property :admin, Boolean, :default => false
  
  # Define if the user has been enabled/disabled
  property :enabled, Boolean, :default => true

  # Define if get avatar from gravatar.com or not
  property :gravatar, Boolean, :default => false
  property :email_reports, Boolean, :default => false
 
  # Define created_at and updated_at timestamps
  timestamps :at

  has_attached_file :avatar,
  :styles => {
    :large => "500x500>",
    :medium => "300x300>",
    :small => "100x100#"
  }, :default_url => '/images/default_avatar.png', :processors => [:cropper],
    :whiny => false

  ##validates_attachment_content_type :avatar, :content_type => ["image/png", "image/gif", "image/jpeg"]

  validates_attachment_content_type :avatar, :content_type => ['image/jpeg', 'image/gif', 'image/png', 'image/pjpeg', 'image/x-png'], 
  :message => 'Uploaded file is not an image', 
  :if => Proc.new { |profile| profile.avatar.file? }

  validates_attachment_size :avatar, :less_than => 2.megabytes, 
  :message => 'Uploaded file is bigger than 2MB', 
  :if => Proc.new { |profile| profile.avatar.file? } 
  
  has n, :notifications, :constraint => :destroy

  has n, :favorites, :child_key => :user_id, :constraint => :destroy
  has n, :rule_favorites, :child_key => :user_id, :constraint => :destroy

  has n, :notes, :child_key => :user_id, :constraint => :destroy

  has n, :events

  has n, :events, :through => :favorites
  has n, :rules, :through => :rule_favorites

  has n, :roles, :through => :roleUser

  has n, :dashboardTabs, :constraint => :destroy
  has n, :snmpTabs, :constraint => :destroy

  has n, :widgets, :constraint => :destroy

  #
  # Converts the user to a String.
  #
  # @return [String]
  #   The name of the user.
  #
  
  
  audit :name, :email, :accept_notes, :per_page_count, :avatar, :gravatar, :admin, :encrypted_password, :login do |action|
    
    if User.current_user.present?
    
      log_attributes = {:model_name => self.class, :action => action, :model_id => self.id, :user => User.current_user}

      case action.to_sym
      when :create
        log_attributes.merge!({:message => "Created #{self.class} '#{self.name}'"})
      when :update
        log_attributes.merge!({:message => changes.collect {|prop, values|

                                                            case prop.name.to_sym
                                                            when :encrypted_password
                                                              "Changed password"
                                                            when :accept_notes
                                                              val_array = ['Yes', 'No', 'Only events I\'ve noted']
                                                              "Changed #{prop.name} from '#{val_array[values[0]]}' to '#{val_array[values[1]]}'"
                                                            else
                                                              "Changed #{prop.name} from '#{values[0]}' to '#{values[1]}'"
                                                            end
                                                          }.join(", ")
                              })
      when :destroy
        log_attributes.merge!({:message => "Destroyed #{self.class} '#{self.name}'"})
      end

      Log.new(log_attributes).save
      
    end

  end
  
  def classify_count
    Event.count(:user_id => self.id.to_i) 
  end
  
  def to_s
    self.name.to_s
  end
  def accepts_note_notifications?(item=false)
    if accept_notes == 1
      return true
    elsif accept_notes == 3
      return false unless item
      return true if added_notes_for_item?(item)
      return false
    else
      return false
    end
  end
  
  def added_notes_for_item?(item)
    begin
      return true if item.notes.map(&:user_id).include?(id)
      false
    rescue NoMethodError => e
      false
    end
  end

  def cropping?
    !crop_x.blank? && !crop_y.blank? && !crop_w.blank? && !crop_h.blank?
  end

  def avatar_geometry(style = :original)
    @geometry ||= {}
    @geometry[style] ||= Paperclip::Geometry.from_file(avatar.path(style))
  end

  def reprocess_avatar
    avatar.reprocess! if cropping?
  end

  def role_ids
    self.roles.map{|r| r.id}
  end

  def role_ids=(roles)
    self.roles = []
    self.roles = Role.all(:id => roles)
    self.save
  end

  def virtual_sensors
    ability = Ability.new(User.current_user)
    Sensor.all(:fields => [:name, :sid], :virtual_sensor => true, :domain => true, :order => :name).select{|s| ability.can?(:read, s)}
  end

  def real_sensors
    ability = Ability.new(User.current_user)
    Sensor.all(:fields => [:name, :sid], :domain=> false, :virtual_sensor=>false).select{|s| ability.can?(:read, s.parent)}
  end
end
