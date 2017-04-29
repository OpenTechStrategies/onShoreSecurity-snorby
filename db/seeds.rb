def db_adapter
  @adapter ||= DataMapper.repository(:default).adapter
end

def db_execute(sql)
  db_adapter.execute(sql)
end

def select(sql)
  db_adapter.select(sql)
end

def options
  @options ||= DataMapper.repository.adapter.options
end

# Constraints

## DATA TABLE
sql = %{SELECT * FROM information_schema.table_constraints 
                 WHERE constraint_schema = '#{options["database"]}' 
                 AND constraint_name = 'data_event_fk';}

if select(sql).empty?                 

  db_execute("ALTER TABLE data ADD CONSTRAINT data_event_fk 
          FOREIGN KEY data_event_fk (sid, cid) 
          REFERENCES event (sid, cid) 
          ON DELETE CASCADE 
          ON UPDATE RESTRICT;")

end

## ICMPHDR TABLE
sql = %{SELECT * FROM information_schema.table_constraints 
                 WHERE constraint_schema = '#{options["database"]}' 
                 AND constraint_name = 'icmphdr_event_fk';}

if select(sql).empty?

  db_execute("ALTER TABLE icmphdr ADD CONSTRAINT icmphdr_event_fk 
          FOREIGN KEY icmphdr_event_fk (sid, cid) 
          REFERENCES event (sid, cid) 
          ON DELETE CASCADE 
          ON UPDATE RESTRICT;")

end

## TCPHDR TABLE
sql = %{SELECT * FROM information_schema.table_constraints 
                 WHERE constraint_schema = '#{options["database"]}' 
                 AND constraint_name = 'tcphdr_event_fk';}

if select(sql).empty?

  db_execute("ALTER TABLE tcphdr ADD CONSTRAINT tcphdr_event_fk 
          FOREIGN KEY tcphdr_event_fk (sid, cid) 
          REFERENCES event (sid, cid) 
          ON DELETE CASCADE 
          ON UPDATE RESTRICT;")

end

## UDPHDR TABLE
sql = %{SELECT * FROM information_schema.table_constraints 
                 WHERE constraint_schema = '#{options["database"]}' 
                 AND constraint_name = 'udphdr_event_fk';}

if select(sql).empty?

  db_execute("ALTER TABLE udphdr ADD CONSTRAINT udphdr_event_fk 
          FOREIGN KEY udphdr_event_fk (sid, cid) 
          REFERENCES event (sid, cid) 
          ON DELETE CASCADE 
          ON UPDATE RESTRICT;")

end

## OPT TABLE
sql = %{SELECT * FROM information_schema.table_constraints 
                 WHERE constraint_schema = '#{options["database"]}' 
                 AND constraint_name = 'opt_event_fk';}

if select(sql).empty?

  db_execute("ALTER TABLE opt ADD CONSTRAINT opt_event_fk 
          FOREIGN KEY opt_event_fk (sid, cid) 
          REFERENCES event (sid, cid) 
          ON DELETE CASCADE 
          ON UPDATE RESTRICT;")

end

## FAVORITES TABLE
sql = %{SELECT * FROM information_schema.table_constraints 
                 WHERE constraint_schema = '#{options["database"]}' 
                 AND constraint_name = 'favorites_event_fk';}

if select(sql).empty?

  db_execute("ALTER TABLE favorites ADD CONSTRAINT favorites_event_fk 
        FOREIGN KEY favorites_event_fk (sid, cid)
        REFERENCES event (sid, cid)
        ON DELETE CASCADE
        ON UPDATE RESTRICT;")

end

## IP TABLE
sql = %{SELECT * FROM information_schema.table_constraints 
                 WHERE constraint_schema = '#{options["database"]}' 
                 AND constraint_name = 'iphdr_event_fk';}

if select(sql).empty?

  db_execute("ALTER TABLE iphdr ADD CONSTRAINT iphdr_event_fk 
        FOREIGN KEY iphdr_event_fk (sid, cid)
        REFERENCES event (sid, cid)
        ON DELETE CASCADE
        ON UPDATE RESTRICT;")

end


# Define the snort schema version
SnortSchema.create(:vseq => 108, :ctime => Time.now, :version => "Snorby #{Snorby::VERSION}") if SnortSchema.first.blank?

# Default user setup
User.create(:name => 'Administrator', :email => 'security@example.com', :password => 'password', :password_confirmation => 'password', :admin => true) if User.all.blank?

# Snorby General Settings
Setting.set(:company, 'redBorder Networks') unless Setting.company?
Setting.set(:email, 'admin@redborder.net') unless Setting.email?
Setting.set(:signature_lookup, 'http://rootedyour.com/snortsid?sid=$$gid$$:$$sid$$') unless Setting.signature_lookup?
Setting.set(:show_disabled_rules) unless Setting.show_disabled_rules?
Setting.set(:flowbits_dependencies) unless Setting.show_disabled_rules?
Setting.set(:daily, true) unless Setting.daily?
Setting.set(:weekly, true) unless Setting.weekly?
Setting.set(:monthly, true) unless Setting.monthly?
Setting.set(:lookups, true) unless Setting.lookups?
Setting.set(:utc, false) #unless Setting.utc?
Setting.set(:notes, true) # unless Setting.notes?
Setting.set(:geoip, true) unless Setting.geoip?
Setting.set(:global_dbversion_id, 1) 
Setting.set(:event_notifications, false) unless Setting.event_notifications?

# Remove Legacy Settings
Setting.get(:openfpc) ? Setting.get(:openfpc).destroy! : nil
Setting.get(:openfpc_url) ? Setting.get(:openfpc_url).destroy! : nil

# Full Packet Capture Support
Setting.set(:packet_capture_url, "") unless Setting.packet_capture_url?
Setting.set(:packet_capture, nil) unless Setting.packet_capture?
Setting.set(:packet_capture_type, 'openfpc') unless Setting.packet_capture_type?
Setting.set(:packet_capture_auto_auth, true) unless Setting.packet_capture_auto_auth?
Setting.set(:packet_capture_user, "") unless Setting.packet_capture_user?
Setting.set(:packet_capture_password, "") unless Setting.packet_capture_password?

# Setting.set(:geoip, nil) unless Setting.geoip?
Setting.set(:autodrop, nil) unless Setting.autodrop?
Setting.set(:autodrop_count, nil) unless Setting.autodrop_count?

Setting.set(:autoreload_time, "99") unless Setting.autoreload_time?

Setting.set(:autodrop_rollback, "1") unless Setting.autodrop?
Setting.set(:autodrop_rollback_count, "20") unless Setting.autodrop_count?

# Proxy Support
Setting.set(:proxy, nil) unless Setting.proxy?
Setting.set(:proxy_address, "") unless Setting.proxy_address?
Setting.set(:proxy_port, "") unless Setting.proxy_port?
Setting.set(:proxy_user, "") unless Setting.proxy_user?
Setting.set(:proxy_password, "") unless Setting.proxy_password?

# Load Default Classifications

Classification.first_or_create({ :name => "Unauthorized Root Access" }, {
  :name => 'Unauthorized Root Access',
  :description => 'Unauthorized Root Access',
  :hotkey => 1,
  :locked => true
})

Classification.first_or_create({ :name => "Unauthorized User Access" }, {
  :name => 'Unauthorized User Access',
  :description => 'Unauthorized User Access',
  :hotkey => 2,
  :locked => true
})

Classification.first_or_create({ :name => "Attempted Unauthorized Access" }, {
  :name => 'Attempted Unauthorized Access',
  :description => 'Attempted Unauthorized Access',
  :hotkey => 3,
  :locked => true
})

Classification.first_or_create({ :name => "Denial of Service Attack" }, {
  :name => 'Denial of Service Attack',
  :description => 'Denial of Service Attack',
  :hotkey => 4,
  :locked => true
})

Classification.first_or_create({ :name => "Policy Violation" }, {
  :name => 'Policy Violation',
  :description => 'Policy Violation',
  :hotkey => 5,
  :locked => true
})

Classification.first_or_create({:name => "Reconnaissance"}, {
  :name => 'Reconnaissance',
  :description => 'Reconnaissance',
  :hotkey => 6,
  :locked => true
})

Classification.first_or_create({:name => "Virus Infection"}, {
  :name => 'Virus Infection',
  :description => 'Virus Infection',
  :hotkey => 7,
  :locked => true
})

Classification.first_or_create({:name => "False Positive"}, {
  :name => 'False Positive',
  :description => 'False Positive',
  :hotkey => 8,
  :locked => true
})

Classification.first_or_create({ :name => "Exploit" }, {
  :name => 'Exploit',
  :description => 'Exploit',
  :locked => false
})

Classification.first_or_create({ :name => "Malware" }, {
  :name => 'Malware',
  :description => 'Malware',
  :locked => false
})

# Load Default Severities
if Severity.all.blank?
  Severity.create(:id => 1, :sig_id => 1, :name => 'High Severity', :text_color => "#ffffff", :bg_color => "#ff0000")
  Severity.create(:id => 2, :sig_id => 2, :name => 'Medium Severity', :text_color => "#ffffff", :bg_color => "#fab908")
  Severity.create(:id => 3, :sig_id => 3, :name => 'Low Severity', :text_color => "#ffffff", :bg_color => "#3a781a")
end

# Validate Snorby Indexes
require "./lib/snorby/jobs/cache_helper"
include Snorby::Jobs::CacheHelper
validate_cache_indexes

# Load Default Action Rules
if RuleAction.all.blank?
  RuleAction.create(:id => 1, :name => 'pass'     , :description => 'Ignore the packet')
  RuleAction.create(:id => 2, :name => 'alert'    , :description => 'Generate an alert using the selected alert method, and then log the packet')
  RuleAction.create(:id => 3, :name => 'drop'     , :description => 'Block and log the packet')
  RuleAction.create(:id => 4, :name => 'log'      , :description => 'Log the packet')
  RuleAction.create(:id => 5, :name => 'sdrop'    , :description => 'Block the packet but do not log it')
  RuleAction.create(:id => 6, :name => 'reject'   , :description => 'Block the packet, log it, and then send a TCP reset if the protocol is TCP or an ICMP port unreachable')
  RuleAction.create(:id => 7, :name => 'inherited', :description => 'This rule will be inherited from its parents.')
end

if Flowbit.all.blank?
  Flowbit.create(:id => 1, :name => 'set'     , :description => 'Sets the specified state for the current flow and unsets all the other flowbits in a group when a GROUP_NAME is specified.')
  Flowbit.create(:id => 2, :name => 'unset'   , :description => 'Unsets the specified state for the current flow.')
  Flowbit.create(:id => 3, :name => 'toggle'  , :description => 'Sets the specified state if the state is unset and unsets all the other flowbits in a group when a GROUP_NAME is specified, otherwise unsets the state if the state is set.')
  Flowbit.create(:id => 4, :name => 'isset'   , :description => 'Checks if the specified state is set.')
  Flowbit.create(:id => 5, :name => 'isnotset', :description => 'Checks if the specified state is not set.')
  Flowbit.create(:id => 6, :name => 'noalert' , :description => 'Cause the rule to not generate an alert, regardless of the rest of the detection options.')
  Flowbit.create(:id => 7, :name => 'reset', :description => 'Reset all states on a given flow.')
end

if Policy.all.blank?
  Policy.create(:id => 1, :name => 'connectivity-ips', :description => "This is a speedy policy for people that insist on blocking only the really known bad with no false positives.")
  Policy.create(:id => 2, :name => 'balanced-ips'    , :description => "This is a good starter policy for everyone. It's quick, has a good base coverage level, and covers the latest threats of the day. This policy contains everything that is in the connectivity-ips policy")
  Policy.create(:id => 3, :name => 'security-ips'    , :description => "This is a stringent policy that everyone should strive to get to through tuning. It's quick, but has some policy-type rules in it. This policy contains everything that is in the security-ips policy.")
end

if RuleCategory4.all.blank?
  RuleCategory4.create(:name => 'services', :description => "Other Services Rules")
  RuleCategory4.create(:name => 'attacks', :description => "Attack Execution or Backtrace Rules")
  RuleCategory4.create(:name => 'special', :description => "External Resources Rules")
  RuleCategory4.create(:name => 'dos', :description => "Denial Of Service Rules")
  RuleCategory4.create(:name => 'web', :description => "Web Service Rules")
  RuleCategory4.create(:name => 'email', :description => "Email Service Rules")
  RuleCategory4.create(:name => 'policy', :description => "Enterprise Policy Violation Rules")
  RuleCategory4.create(:name => 'others', :description => "Other Rules")
  RuleCategory4.create(:name => 'sql', :description => "Database Service Rules")
  RuleCategory4.create(:name => 'preprocessors', :description => "Preprocessor (Snort Internal's) Rules")
end

if ReputationAction.all.blank?
  ReputationAction.create(:id => 1, :name => 'analize', :color => '#ff9900')
  ReputationAction.create(:id => 2, :name => 'bypass', :color => 'seagreen')
  ReputationAction.create(:id => 3, :name => 'drop', :color => '#cc3300')
end

if ReputationType.all.blank?
  ReputationType.create(:id => 1, :name => 'ip_network')
  ReputationType.create(:id => 2, :name => 'country')
end

Rbreference.first_or_create({:name => 'bugtraq'}  , {:name => 'bugtraq'  , :prefix => 'http://www.securityfocus.com/bid/'})
Rbreference.first_or_create({:name => 'cve'}      , {:name => 'cve'      , :prefix => 'http://cve.mitre.org/cgi-bin/cvename.cgi?name='})
Rbreference.first_or_create({:name => 'nessus'}   , {:name => 'nessus'   , :prefix => 'http://cgi.nessus.org/plugins/dump.php3?id='})
Rbreference.first_or_create({:name => 'url'}      , {:name => 'url'      , :prefix => 'http://'})
Rbreference.first_or_create({:name => 'arachnids'}, {:name => 'arachnids', :prefix => 'http://www.whitehats.com/info/IDS'})
Rbreference.first_or_create({:name => 'mcafee'}   , {:name => 'mcafee'   , :prefix => 'http://vil.nai.com/vil/content/v_'})
Rbreference.first_or_create({:name => 'osvdb'}    , {:name => 'osvdb'    , :prefix => 'http://osvdb.org/show/osvdb/'})

Service.first_or_create({:name => 'tftp'}       , {:name => 'tftp', :description => 'Trivial file transfer Protocol'})
Service.first_or_create({:name => 'http'}       , {:name => 'http', :description => 'Hypertext Transfer Protocol'})
Service.first_or_create({:name => 'ssl'}        , {:name => 'ssl', :description => 'Secure Sockets Layer'})
Service.first_or_create({:name => 'kerberos'}   , {:name => 'kerberos', :description => 'kerberos authentication protocol'})
Service.first_or_create({:name => 'dcerpc'}     , {:name => 'dcerpc', :description => 'Distributed Computing Environment / Remote Procedure Calls'})
Service.first_or_create({:name => 'smtp'}       , {:name => 'smtp', :description => 'Simple Mail Transfer Protocol'})
Service.first_or_create({:name => 'pop3'}       , {:name => 'pop3', :description => 'Post Office Protocol'})
Service.first_or_create({:name => 'nntp'}       , {:name => 'nntp', :description => 'Network News Transfer Protocol'})
Service.first_or_create({:name => 'dns'}        , {:name => 'dns', :description => 'Domain Name System'})
Service.first_or_create({:name => 'ircd'}       , {:name => 'ircd', :description => 'Internet Relay Chat daemon'})
Service.first_or_create({:name => 'mysql'}      , {:name => 'mysql', :description => 'Mysql databases'})
Service.first_or_create({:name => 'sunrpc'}     , {:name => 'sunrpc', :description => 'Sun Microsystems Remote Procedure Call'})
Service.first_or_create({:name => 'netbios-ssn'}, {:name => 'netbios-ssn', :description => 'Netbios-SSN'})
Service.first_or_create({:name => 'ident'}      , {:name => 'ident', :description => 'Ident Protocol'})
Service.first_or_create({:name => 'netbios-dgm'}, {:name => 'netbios-dgm', :description => 'Netbios-DGM'})
Service.first_or_create({:name => 'ntp'}        , {:name => 'ntp', :description => 'Network Time Protocol'})
Service.first_or_create({:name => 'ldap'}       , {:name => 'ldap', :description => 'Lightweight Directory Access Protocol'})
Service.first_or_create({:name => 'netbios-ns'} , {:name => 'netbios-ns', :description => 'Netbios-NS'})
Service.first_or_create({:name => 'ftp'}        , {:name => 'ftp', :description => 'File Transfer Protocol'})
Service.first_or_create({:name => 'rtsp'}       , {:name => 'rtsp', :description => 'Real Time Streaming Protocol'})
Service.first_or_create({:name => 'imap'}       , {:name => 'imap', :description => 'Internet Message Access Protocol'})
Service.first_or_create({:name => 'ftp-data'}   , {:name => 'ftp-data', :description => 'File Transfer Protocol - Data'})
Service.first_or_create({:name => 'telnet'}     , {:name => 'telnet', :description => 'Telnet protocol'})
Service.first_or_create({:name => 'ssh'}        , {:name => 'ssh', :description => 'Secure Shell'})
Service.first_or_create({:name => 'pop '}       , {:name => 'pop', :description => 'Post Office Protocol'})

# Sensor root. No quitar dbversion_id => 1 porque el valor por defecto no vale
Sensor.first_or_create({:name=>"root"}, {:name => "root", :parent_sid=>0, :domain => true, :dbversion_id => 1})
rc1 = RuleCompilation.first_or_create({:id => 1}, {:timestamp => Time.now, :name => "Initial state", :user => User.first, :sensor => Sensor.root});

r = RuleSource.first(:name => 'vrt')
if r.nil?
  RuleSource.create(:name => "vrt", :timestamp => Time.now, :description => "Sourcefire Vulnerability Research Team", :protected => true, :tgzurl => "https://www.snort.org/reg-rules/snortrules-snapshot-2940.tar.gz/$$code$$", :md5url => "https://www.snort.org/reg-rules/snortrules-snapshot-2940.tar.gz.md5/$$code$$", :md5 => nil, :search => ["rules", "preproc_rules", "so_rules"].to_json, :so_rules => ["so_rules/precompiled/RHEL-6-0/x86-64"].to_json, :has_code => true)
else
  r.update(:timestamp => Time.now, :description => "Sourcefire Vulnerability Research Team", :protected => true, :tgzurl => "https://www.snort.org/reg-rules/snortrules-snapshot-2940.tar.gz/$$code$$", :md5url => "https://www.snort.org/reg-rules/snortrules-snapshot-2940.tar.gz.md5/$$code$$", :md5 => nil, :search => ["rules", "preproc_rules", "so_rules"].to_json, :so_rules => ["so_rules/precompiled/RHEL-6-0/x86-64"].to_json, :has_code => true)
end

r = RuleSource.first(:name => 'etpro')
if r.nil?
  RuleSource.create(:name => "etpro", :timestamp => Time.now, :description => "Emerging Threats PRO rules", :protected => true, :tgzurl => "https://rules.emergingthreats.net/$$code$$/snort-2.9.3/etpro.rules.tar.gz", :md5url => "https://rules.emergingthreats.net/$$code$$/snort-2.9.3/etpro.rules.tar.gz.md5", :regexp_category3_ignore => "^et |^gpl |^etpro ", :md5 => nil, :search => ["rules"].to_json, :so_rules => [].to_json, :has_code => true)
else
  r.update(:timestamp => Time.now, :description => "Emerging Threats PRO rules", :protected => true, :tgzurl => "https://rules.emergingthreats.net/$$code$$/snort-2.9.3/etpro.rules.tar.gz", :md5url => "https://rules.emergingthreats.net/$$code$$/snort-2.9.3/etpro.rules.tar.gz.md5", :regexp_category3_ignore => "^et |^gpl |^etpro ", :md5 => nil, :search => ["rules"].to_json, :so_rules => [].to_json, :has_code => true)
end

r = RuleSource.first(:name => 'emergingthreats')
if r.nil?
  RuleSource.create(:name => "emergingthreats", :timestamp => Time.now, :description => "Emerging Threats community rules", :protected => true, :tgzurl => "https://rules.emergingthreats.net/open/snort-2.9.3/emerging.rules.tar.gz", :md5url => "https://rules.emergingthreats.net/open/snort-2.9.3/emerging.rules.tar.gz.md5", :regexp_category1_ignore => "emerging-", :regexp_category3_ignore => "^et |^gpl ", :md5 => nil, :search => ["rules"].to_json, :so_rules => [].to_json)
else
  r.update(:timestamp => Time.now, :description => "Emerging Threats community rules", :protected => true, :tgzurl => "https://rules.emergingthreats.net/open/snort-2.9.3/emerging.rules.tar.gz", :md5url => "https://rules.emergingthreats.net/open/snort-2.9.3/emerging.rules.tar.gz.md5", :regexp_category1_ignore => "emerging-", :regexp_category3_ignore => "^et |^gpl ", :md5 => nil, :search => ["rules"].to_json, :so_rules => [].to_json)
end

Sensor.all(:compilation_id => 0, :domain => true).each do |x| 
  candidate = RuleCompilation.get(x.sensorRules.max(:compilation_id))
  if candidate.present?
    x.update(:compilation => candidate)
  else
    x.update(:compilation => RuleCompilation.first)
  end
end

SnortStatName.first_or_create({:name => 'time'}, {:name => "time",  :text_name => 'Time', :measure_unit => nil, :enable => false})
SnortStatName.first_or_create({:name => 'wire_mbits_per_sec.realtime'}, {:name => "wire_mbits_per_sec.realtime",  :text_name => 'Mbps', :measure_unit => 'Mbps', :enable => true})
SnortStatName.first_or_create({:name => 'kpackets_wire_per_sec.realtime'}, {:name => "kpackets_wire_per_sec.realtime",  :text_name => 'Kpps', :measure_unit => 'Kpps', :enable => true})
SnortStatName.first_or_create({:name => 'cpu'}, {:name => "cpu",  :text_name => 'CPU', :measure_unit => '%', :enable => true})
SnortStatName.first_or_create({:name => 'pkt_drop_percent'}, {:name => "pkt_drop_percent",  :text_name => 'Packets Dropped', :measure_unit => '%', :enable => true})
SnortStatName.first_or_create({:name => 'alerts_per_second'}, {:name => "alerts_per_second",  :text_name => 'Alerts', :measure_unit => 'alerts/second', :enable => true})
SnortStatName.first_or_create({:name => 'alerts_per_minute'}, {:name => "alerts_per_minute",  :text_name => 'Alerts', :measure_unit => 'alerts/minute', :enable => true})
SnortStatName.first_or_create({:name => 'total_sessions'}, {:name => "total_sessions",  :text_name => 'Sessions', :measure_unit => 'sessions', :enable => true})


Lookup.first_or_create({:title => "uTrace"}, {:title => "uTrace", :value => "http://en.utrace.de/?query=${ip}"})
Lookup.first_or_create({:title => "Trusted Source"}, {:title => "Trusted Source", :value => "http://www.mcafee.com/threat-intelligence/ip/default.aspx?ip=${ip}"})
Lookup.first_or_create({:title => "whois.sc"}, {:title => "whois.sc", :value => "http://www.whois.sc/${ip}"})


