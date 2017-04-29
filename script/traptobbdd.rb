#!/usr/bin/ruby

require 'rubygems'
#require 'datamapper'
require 'dm-core'
require 'dm-rails'
require 'dm-do-adapter'
require 'dm-active_model'
require 'dm-mysql-adapter'
require 'dm-migrations'
require 'dm-types'
require 'dm-validations'
require 'dm-constraints'
require 'dm-transactions'
require 'dm-aggregates'
require 'dm-timestamps'
require 'dm-observer'
require 'dm-serializer'

PRG_VERSION="1.0"

db_config = File.read("#{File.dirname(__FILE__)}/../config/database.yml")
CONFIG = YAML.load(db_config)[Rails.env].symbolize_keys

DataMapper.setup(
  :default,
  {:adapter => CONFIG[:adapter],
  :username => CONFIG[:username],
  :password => CONFIG[:password],
  :host     => CONFIG[:host],
  :database => CONFIG[:database]}
)

class Trap
  include DataMapper::Resource
  property :id, Serial
  property :sid, Integer
  property :ip, String
  property :port, Integer
  property :protocol, String
  property :hostname, String
  property :community, String
  property :message, String, :length => 512
  property :trigger, String, :length => 64
  property :timestamp, DateTime
end

class Sensor
  include DataMapper::Resource
  storage_names[:default] = "sensor"
  property :sid, Serial, :key => true, :index => true
  property :ipdir, String
end

hostname  = nil
ipaddress = nil
port      = nil
protocol  = nil
msg       = nil


ARGF.each_with_index do |line, idx|
  line.chop!
  if idx==0
    hostname=line
  elsif idx==1
    ipaddress=line
  elsif idx==2
    msg = line
  else
    msg = msg +"; " +line
  end
end

#+-----------+------------------+------+-----+---------+----------------+
#| Field     | Type             | Null | Key | Default | Extra          |
#+-----------+------------------+------+-----+---------+----------------+
#| id        | int(10) unsigned | NO   | PRI | NULL    | auto_increment |
#| ip        | varchar(50)      | YES  |     | NULL    |                |
#| port      | int(11)          | YES  |     | NULL    |                |
#| protocol  | varchar(50)      | YES  |     | NULL    |                |
#| hostname  | varchar(50)      | YES  |     | NULL    |                |
#| community | varchar(50)      | YES  |     | NULL    |                |
#| message   | varchar(512)     | YES  |     | NULL    |                |
#| timestamp | datetime         | YES  |     | NULL    |                |
#+-----------+------------------+------+-----+---------+----------------+

#UDP: [192.168.122.51]:52024->[192.168.122.53] | redBorder | DISMAN-EVENT-MIB::sysUpTimeInstance 0:0:04:30 ... | 2011-10-27 18:12:59
#echo -e "<UNKNOWN>\nUDP: [192.168.100.32]:51053->[192.168.11.110]\nDISMAN-EVENT-MIB::sysUpTimeInstance 0:19:00:50.10\nSNMPv2-MIB::snmpTrapOID.0 DISMAN-EVENT-MIB::mteTriggerFired\nDISMAN-EVENT-MIB::mteHotTrigger.0 barnyard2-stopped\nDISMAN-EVENT-MIB::mteHotTargetName.0\nDISMAN-EVENT-MIB::mteHotContextName.0\nDISMAN-EVENT-MIB::mteHotOID.0 UCD-SNMP-MIB::prCount.4\nDISMAN-EVENT-MIB::mteHotValue.0 0" | #{CONFIG[:console_path]}/script/traptobbdd.rb

if hostname.length>=47
  hostname = hostname.slice(0,45) + " ..."
end

if msg.length>=508
  msg = msg.slice(0,508) + " ..."
end

r = /([^:]+): \[([^\]]+)\]:([0-9]+)/
m = r.match ipaddress

if !m.nil? && m.length>3
  protocol  = m[1]
  ipaddress = m[2]
  port      = m[3].to_i
  sensor    = Sensor.last(:ipdir=>ipaddress)
  msg       = msg.gsub('DISMAN-EVENT-MIB::', '').gsub('SNMPv2-MIB::', '')
  trigger   = nil
  
  match = /.*;[\s]*mteHotTrigger.[\d]+[\s]([^;]+);.*/.match msg
  trigger = match[1] unless match.nil?

  if trigger.nil?
    match = /.*;[\s]*snmpTrapOID.0[\s](NET-SNMP-AGENT-MIB::)?([^;]+);.*/.match msg
    trigger = match[2] unless match.nil?
  end

  trigger   = "unknown" if trigger.nil?

  if sensor.nil?
    system("logger -t traptobbdd \"Trap no valid. Sensor with ip #{ipaddress} not found!!\" ")
  else
    if !hostname.nil? && !ipaddress.nil? && !msg.nil? && !protocol.nil? && !port.nil?
      #Trap.create(:ip => ipaddress, :hostname => hostname, :protocol => protocol, :port => port, :community => "redBorder", :message => msg, :timestamp => Time.now)
      t = Trap.new();
      t.ip  = ipaddress;
      t.sid = sensor.sid;
      t.hostname  = hostname
      t.protocol  = protocol
      t.port      = port
      t.community = "cry5t@l"
      t.message   = msg
      t.trigger   = trigger
      t.timestamp = Time.now
      t.save
    else
      system("logger -t traptobbdd \"Trap no valid. It should have more parameters!!\" ")
    end
  end
else
  system("logger -t traptobbdd \"Trap no valid!!\" ")
end


