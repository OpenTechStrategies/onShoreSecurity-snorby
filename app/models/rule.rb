require 'snorby/model/counter'

class Rule
  # Version for each rule. Each time the rules2rbIPS script is executed, if it detects new rules it create a new dbversion.
  #    All the rules downloaded will have the same dbversion reference. A rule actualization will involve the script will 
  #    download all rules again creating a new dbversion entry for those rules.
  SIGNATURE_URL = "http://rootedyour.com/snortsid?sid=$$gid$$-$$sid$$"

  include DataMapper::Resource
  include Snorby::Model::Counter
  
  extend ActionView::Helpers::TextHelper

  PROTOCOL = {"TCP" => 'tcp', "UDP" => 'udp', "ICMP" => "", "SYSLOG" => 'syslog'}
  MODIFIER = {
    :nocase => "The nocase keyword allows the rule writer to specify that the Snort should look for the specific pattern, ignoring case",
    :rawbytes => "The rawbytes keyword allows rules to look at the raw packet data, ignoring any decoding that was done by preprocessors",
    :depth => "The depth keyword allows the rule writer to specify how far into a packet Snort should search for the specified pattern",
    :offset => "The offset keyword allows the rule writer to specify where to start searching for a pattern within a packet",
    :distance => "The distance keyword allows the rule writer to specify how far into a packet Snort should ignore before starting to search for the specified pattern relative to the end of the previous pattern match",
    :within => "The within keyword is a content modifier that makes sure that at most N bytes are between pattern matches using the content keyword",
    :http_client_body => "The http_client_body keyword is a content modifier that restricts the search to the body of an HTTP client request",
    :http_cookie => "The http_cookie keyword is a content modifier that restricts the search to the extracted Cookie Header field (excluding the header name itself and the CRLF terminating the header line) of a HTTP client request or a HTTP server response",
    :http_raw_cookie => "The http_raw_cookie keyword is a content modifier that restricts the search to the extracted UNNORMALIZED Cookie Header field of a HTTP client request or a HTTP server response",
    :http_header => "The http_header keyword is a content modifier that restricts the search to the extracted Header fields of a HTTP client request or a HTTP server response",
    :http_raw_header => "The http_raw_header keyword is a content modifier that restricts the search to the extracted UNNORMALIZED Header fields of a HTTP client request or a HTTP server response",
    :http_method => "The http_method keyword is a content modifier that restricts the search to the extracted Method from a HTTP client request",
    :http_uri => "The http_uri keyword is a content modifier that restricts the search to the NORMALIZED request URI field",
    :http_raw_uri => "The http_raw_uri keyword is a content modifier that restricts the search to the UNNORMALIZED request URI field",
    :http_stat_code => "The http_stat_code keyword is a content modifier that restricts the search to the extracted Status code field from a HTTP server response",
    :http_stat_msg => "The http_stat_msg keyword is a content modifier that restricts the search to the extracted Status Message field from a HTTP server response",
    :http_encode => "The http_encode keyword will enable alerting based on encoding type present in a HTTP client request or a HTTP server response",
    :fast_pattern => "The fast_pattern keyword is a content modifier that sets the content within a rule to be used with the fast pattern matcher. Since the default behavior of fast pattern determination is to use the longest content in the rule, it is useful if a shorter content is more \"unique\" than the longer content, meaning the shorter content is less likely to be found in a packet than the longer content"
  }
  HELP = {
    :msg => "The msg rule option tells the logging and alerting engine the message to print along with a packet dump or to an alert",
    :reference => "The reference keyword allows rules to include references to external attack identification systems",
    :gid => "The gid keyword (generator id) is used to identify what part of Snort generates the event when a particular rule fires. For example gid 1 is associated with the rules subsystem and various gids over 100 are designated for specific preprocessors and the decoder",
    :sid => "The sid keyword is used to uniquely identify Snort rules",
    :rev => "The rev keyword is used to uniquely identify revisions of Snort rules. Revisions, along with Snort rule id's, allow signatures and descriptions to be refined and replaced with updated information",
    :classtype => "The classtype keyword is used to categorize a rule as detecting an attack that is part of a more general type of attack class. Snort provides a default set of attack classes that are used by the default set of rules it provides",
    :priority => "The priority tag assigns a severity level to rules",
    :metadata => "The metadata tag allows a rule writer to embed additional information about the rule, typically in a key-value format",
    :content => "The content keyword is one of the more important features of Snort. It allows the user to set rules that search for specific content in the packet payload and trigger response based on that data. Whenever a content option pattern match is performed, the Boyer-Moore pattern match function is called and the (rather computationally expensive) test is performed against the packet contents. If data exactly matching the argument data string is contained anywhere within the packet's payload, the test is successful and the remainder of the rule option tests are performed",
   :uricontent => "The uricontent keyword in the Snort rule language searches the NORMALIZED request URI field. This is equivalent to using the http_uri modifier to a content keyword",
    :urilen => "The urilen keyword in the Snort rule language specifies the exact length, the minimum length, the maximum length, or range of URI lengths to match. By default the raw uri buffer will be used",
    :isdataat => "Verify that the payload has data at a specified location, optionally looking for data relative to the end of the previous content match",
    :pcre => "The pcre keyword allows rules to be written using perl compatible regular expressions",
    :pkt_data => "This option sets the cursor used for detection to the raw transport payload",
    :file_data => "This option sets the cursor used for detection to one of the following buffers: 1. When the traffic being detected is HTTP it sets the buffer to, a. HTTP response body (without chunking/compression/normalization) b. HTTP de-chunked response body c. HTTP decompressed response body (when inspect_gzip is turned on) d. HTTP normalized response body (when normalized_javascript is turned on) e. HTTP UTF normalized response body (when normalize_utf is turned on) f. All of the above 2. When the traffic being detected is SMTP/POP/IMAP it sets the buffer to, a. SMTP/POP/IMAP data body (including Email headers and MIME when decoding is turned off) b. Base64 decoded MIME attachment (when b64_decode_depth is greater than -1) c. Non-Encoded MIME attachment (when bitenc_decode_depth is greater than -1) d. Quoted-Printable decoded MIME attachment (when qp_decode_depth is greater than -1) e. Unix-to-Unix decoded attachment (when uu_decode_depth is greater than -1)",
    :base64_decode => "This option is used to decode the base64 encoded data. This option is particularly useful in case of HTTP headers such as HTTP authorization headers. This option unfolds the data before decoding it",
    :base64_data => "This option is similar to the rule option file_data and is used to set the corsor used for detection to the beginning of the base64 decoded buffer if present",
    :byte_test => "Test a byte field against a specific value (with operator). Capable of testing binary values or converting representative byte strings to their binary equivalent and testing them",
    :byte_jump => "The byte_jump keyword allows rules to be written for length encoded protocols trivially. By having an option that reads the length of a portion of data, then skips that far forward in the packet, rules can be written that skip over specific portions of length-encoded protocols and perform detection in very specific locations",
    :byte_extract => "The byte_extract keyword is another useful option for writing rules against length-encoded protocols. It reads in some number of bytes from the packet payload and saves it to a variable. These variables can be referenced later in the rule, instead of using hard-coded values",
    :ftpbounce => "The ftpbounce keyword detects FTP bounce attacks",
    :asn1 => "The ASN.1 detection plugin decodes a packet or a portion of a packet, and looks for various malicious encodings",
    :cvs => "The CVS detection plugin aids in the detection of: Bugtraq-10384, CVE-2004-0396: \"Malformed Entry Modified and Unchanged flag insertion\". Default CVS server ports are 2401 and 514 and are included in the default ports for stream reassembly",
    :dce_iface => nil,
    :dce_opnum => nil,
    :dce_stub_data => nil,
    :sip_method => nil,
    :sip_stat_code => nil,
    :sip_header => nil,
    :sip_body => nil,
    :gtp_type => nil,
    :gtp_info => nil,
    :gtp_version => nil,
    :ssl_version => nil,
    :ssl_state => nil,
    :fragoffset => "The fragoffset keyword allows one to compare the IP fragment offset field against a decimal value. To catch all the first fragments of an IP session, you could use the fragbits keyword and look for the More fragments option in conjunction with a fragoffset of 0",
    :ttl => "The ttl keyword is used to check the IP time-to-live value. This option keyword was intended for use in the detection of traceroute attempts. This keyword takes numbers from 0 to 255",
    :tos => "The tos keyword is used to check the IP TOS field for a specific value",
    :id => "The id keyword is used to check the IP ID field for a specific value. Some tools (exploits, scanners and other odd programs) set this field specifically for various purposes, for example, the value 31337 is very popular with some hackers",
    :ipopts => "The ipopts keyword is used to check if a specific IP option is present",
    :fragbits => "The fragbits keyword is used to check if fragmentation and reserved bits are set in the IP header",
    :dsize => "The dsize keyword is used to test the packet payload size. This may be used to check for abnormally sized packets that might cause buffer overflows",
    :flags => "The flags keyword is used to check if specific TCP flag bits are present",
    :flow => "The flow keyword is used in conjunction with TCP stream reassembly. It allows rules to only apply to certain directions of the traffic flow",
    :flowbits => "It allows rules to track states during a transport protocol session. The flowbits option is most useful for TCP sessions, as it allows rules to generically track the state of an application protocol",
    :seq => "The seq keyword is used to check for a specific TCP sequence number",
    :ack => "The ack keyword is used to check for a specific TCP acknowledge number",
    :window => "The window keyword is used to check for a specific TCP window size",
    :itype => "The itype keyword is used to check for a specific ICMP type value",
    :icode => "The icode keyword is used to check for a specific ICMP code value",
    :icmp_id => "The icmp_id keyword is used to check for a specific ICMP ID value",
    :icmp_seq => "The icmp_seq keyword is used to check for a specific ICMP sequence value",
    :rpc => "The rpc keyword is used to check for a RPC application, version, and procedure numbers in SUNRPC CALL requests",
    :ip_proto => "The ip_proto keyword allows checks against the IP protocol header",
    :sameip => "The sameip keyword allows rules to check if the source ip is the same as the destination IP",
    :stream_reassemble => "The stream_reassemble keyword allows a rule to enable or disable TCP stream reassembly on matching traffic",
    :stream_size => "The stream_size keyword allows a rule to match traffic according to the number of bytes observed, as determined by the TCP sequence numbers",
    :logto => "The logto keyword tells Snort to log all packets that trigger this rule to a special output log file",
    :session => "The session keyword is built to extract user data from TCP Sessions. There are many cases where seeing what users are typing in telnet, rlogin, ftp, or even web sessions is very useful",
    :resp => "The resp keyword enables an active response that kills the offending session",
    :react => "The react keyword enables an active response that includes sending a web page or other content to the client and then closing the connection",
    :tag => "The tag keyword allow rules to log more than just the single packet that triggered the rule. Once a rule is triggered, additional traffic involving the source and/or destination host is tagged. Tagged traffic is logged to allow analysis of response codes and post-attack traffic",
    :activates => "The activates keyword allows the rule writer to specify a rule to add when a specific network event occurs",
    :activated_by => "The activated_by keyword allows the rule writer to dynamically enable a rule when a specific activate rule is triggered",
    :count => "The count keyword must be used in combination with the activated_by keyword. It allows the rule writer to specify how many packets to leave the rule enabled for after it is activated",
    :replace => "The replace keyword is a feature available in IPS mode which will cause Snort to replace the prior matching content with the given string. Both the new string and the content it is to replace must have the same length. You can have multiple replacements within a rule, one per content",
    :detection_filter => "detection_filter defines a rate which must be exceeded by a source or destination host before a rule can generate an event"
  }

  property :id, Serial, :key => true, :index => true
  property :rule_id, Integer, :index => true, :required => true
  property :gid, Integer, :default => 1
  property :msg, String, :length => 2048, :required => true
  property :short_msg, String, :length => 2048, :required => true
  property :protocol, String, :length => 16
  property :source_addr, String, :length => 4096
  property :source_port, String, :length => 512
  property :target_addr, String, :length => 4096
  property :target_port, String, :length => 512
  property :rev, Integer, :default => 0
  property :rule, String, :length => 8192, :required => true
  property :default_enabled, Boolean, :default => true
  property :users_count, Integer, :index => true, :default => 0
  property :is_new, Boolean, :default => false
  property :is_deprecated, Boolean, :default => false
  property :is_modified, Boolean, :default => false

  belongs_to :category1, :model => 'RuleCategory1', :parent_key => :id, :child_key => :category1_id, :required => true
  belongs_to :category2, :model => 'RuleCategory2', :parent_key => :id, :child_key => :category2_id, :required => true
  belongs_to :category3, :model => 'RuleCategory3', :parent_key => :id, :child_key => :category3_id, :required => true
  belongs_to :category4, :model => 'RuleCategory4', :parent_key => :id, :child_key => :category4_id, :required => true
  belongs_to :classtype, :model => 'RuleCategory2', :parent_key => :id, :child_key => :category2_id, :required => true
  belongs_to :dbversion, :model => 'RuleDbversion', :parent_key => :id, :child_key => :dbversion_id, :required => true
  belongs_to :source   , :model => 'RuleSource'   , :parent_key => :id, :child_key => :source_id   , :required => true

  has n, :sensorRules
  has n, :sensors, :model => 'Sensor'  , :child_key => [ :sid ], :parent_key => [ :rule_id ], :through => :sensorRules
  has n, :notes  , :model => 'RuleNote', :child_key => [ :rule_sid, :rule_gid ], :parent_key => [ :rule_id, :gid ]

  has n, :rule_policies, :model => 'RulePolicy', :child_key => [ :rule_id ], :parent_key => [ :id ], :constraint => :destroy
  has n, :policies, :through => :rule_policies

  has n, :rule_impacts, :model => 'RuleImpact', :child_key => [ :rule_id ], :parent_key => [ :id ], :constraint => :destroy
  has n, :impacts, :through => :rule_impacts

  has n, :rule_services, :model => 'RuleService', :child_key => [ :rule_id ], :parent_key => [ :id ], :constraint => :destroy
  has n, :services, :through => :rule_services

  has n, :rule_references, :model => 'RuleRbreference', :child_key => [ :rule_id ], :parent_key => [ :id ], :constraint => :destroy
  has n, :references, :model => 'Rbreference', :through => :rule_references

  has n, :rule_flowbits, :model => 'RuleFlowbit', :child_key => [ :rule_id ], :parent_key => [ :id ], :constraint => :destroy
  has n, :flowbits, :through => :rule_flowbits

  has n, :versions  , self, :child_key => [ :rule_id, :gid ], :parent_key => [ :rule_id, :gid ]
  has n, :versions_source, self, :child_key => [ :rule_id, :gid, :source_id  ], :parent_key => [ :rule_id, :gid, :source_id ]

  has n, :favorites, :model => 'RuleFavorite', :parent_key => [ :rule_id ], :child_key => [ :rule_id ], :constraint => :destroy
  has n, :users, :through => :favorites

  has 1, :severity, :through => :category2


  has n, :compilations, :through => :sensorRules, :model => 'RuleCompilation'

  def id_email
    "#{rule_id}.#{gid}"
  end

  # array with all versions for one single rule
  def dbversions
    Rule.all(:rule_id => self.rule_id, :source => self.source).map{|x| x.dbversion}.uniq
  end

  def signature_url
    sid, gid = [/\$\$sid\$\$/, /\$\$gid\$\$/]

    @signature_url = if Setting.signature_lookup?
      Setting.find(:signature_lookup)
    else
      SIGNATURE_URL
    end

    @signature_url.sub(sid, self.rule_id.to_s).sub(gid, self.gid.to_s)
  end

  def short_msg
    if super.nil? or super.blank?
      return msg
    end
    super
  end

  def html_id
    "rule_#{id}"
  end

  def favorite?
    return true if User.current_user.rules.include?(self)
    false
  end

  def toggle_favorite
    if self.favorite?
      destroy_favorite
    else
      create_favorite
    end
  end

  def modify_favorite(create=true)
    if create
      flag = create_favorite
    else
      flag = destroy_favorite
    end
    flag
  end
  
  def create_favorite
    favorite = nil
    if !self.favorite?
      favorite = RuleFavorite.create(:rule_id => self.rule_id, :user => User.current_user)
    end
    !favorite.nil?
  end

  def destroy_favorite
    deleted = false
    if self.favorite?
      favorite = User.current_user.rule_favorites.first(:rule_id => self.rule_id )
      if favorite
        deleted = true
        favorite.destroy!
      end
    end
    deleted
  end

  def self.find_by_ids(ids)
    return Rule.all(:id => ids.split(','))
  end

  def self.protocols
    Rule.all(:fields => [:protocol], :unique => true).map{|r1| r1.protocol}.select{|r2| r2.present?}
  end

end
