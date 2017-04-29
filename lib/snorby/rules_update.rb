#!script/rails runner
#
# Copyright (c) 2011 redBorder Networks
# Authors:
# 	Pablo Nebrera Herrera  pablonebrera@eneotecnologia.com
#	  Juan Jesus Prieto:     jjprieto@eneotecnologia.com
#	  Jose Antonio Parra:    japarra@eneotecnologia.com
#
#  Description:
#	It reads the configuration from config/rules2rbIPS.yml. Format:
#		verbose: false
#		cache_dir: "/var/www/snortrules/cache"
#
###########################################################################################################

require 'yaml'
require 'net/http'
require 'tempfile'
require 'digest/md5'

module Snorby

  class RulesUpdate
    # If 'path_rules_dir' is set, it will be executed reading the rules from the directory

    def self.start(verbose=false, initial_tgz = nil, source = nil)
      timenow   = Time.now

      if source.nil?
        sources   = RuleSource.all(:enable=>true, :order => :id)
      else
        sources   = RuleSource.all(:id => source.id)
      end

      config = YAML.load_file("#{CONFIG[:console_path]}/config/rules2rbIPS.yml")

      config["verbose"]   = verbose  if verbose
      config["verbose"]   = false    if config["verbose"].nil?
      config["cache_dir"] = "#{CONFIG[:console_path]}/snortrules/cache" if config["cache_dir"].nil?

      logit "Starting Rules Update" if config["verbose"]
      new_rules      = false    # if true we have new rules and we will create a new dbversion. 
      suspend_update = false    # if true the update will be canceled

      #Download rules from each source
      sources.each do |rs|
        begin
          next if suspend_update
          if initial_tgz.nil?
            dFile           = true  #if true we need to download the file from rs.full_tgzurl
            tgzLocalFile    = "#{config["cache_dir"]}/#{rs.name}.tgz"
          else
            dFile           = false
            tgzLocalFile    = initial_tgz
          end

          tgzLocalFileTmp  = "#{config["cache_dir"]}/#{rs.name}-tmp.tgz"
          remoteMd5Content = nil
          

          if File.exists?(tgzLocalFile) && initial_tgz.nil?
            md5LocalFile = "#{config["cache_dir"]}/#{rs.name}.md5"
            # By default we will have to download the file allways 
            dFile = true

            unless rs.md5url.nil?
              #We compare remote md5 with local one
              logit "Downloading #{rs.full_md5url}" if config["verbose"]
              logit "  * Saving file in #{md5LocalFile}" if config["verbose"]
              download_file(rs.full_md5url, md5LocalFile)
              remoteMd5Content = File.open(md5LocalFile).first.chop.gsub(/^"/, '')
              localMd5Content  = Digest::MD5.hexdigest(File.read(tgzLocalFile));

              if (localMd5Content==remoteMd5Content)
                logit "  * The local file #{tgzLocalFile} is the same than remote file" if config["verbose"]
                dFile = false    #we don't need to download the file
              else
                logit "     - #{tgzLocalFile}  MD5 -> #{localMd5Content}" if config["verbose"]
                logit "     - #{rs.full_tgzurl}  MD5 -> #{remoteMd5Content}"    if config["verbose"]
              end
            end
          end

          if dFile
            logit "Downloading #{rs.full_tgzurl}" if config["verbose"]
            logit "  * Saving file in #{tgzLocalFileTmp}" if config["verbose"]
            download_file(rs.full_tgzurl, tgzLocalFileTmp)

            #check if the file is correct
           # if !remoteMd5Content.nil? and remoteMd5Content!=Digest::MD5.hexdigest(File.read(tgzLocalFileTmp))
           #   new_rules=false
           #   suspend_update=true
           #   logit "  * The downloaded file doesn't match with the indicated in the MD5 URL"    if config["verbose"]
           # end
          end

          if File.exists?(tgzLocalFileTmp) and !suspend_update
            if File.exists?(tgzLocalFile)
              localMd5Content    = Digest::MD5.hexdigest(File.read(tgzLocalFile));
              localMd5ContentTmp = Digest::MD5.hexdigest(File.read(tgzLocalFileTmp));

              if localMd5Content!=localMd5ContentTmp
                new_rules=true
              end
            else
              new_rules=true
            end
            `mv #{tgzLocalFileTmp} #{tgzLocalFile}`
          end

          if File.exists?(tgzLocalFile) and !suspend_update
            if Digest::MD5.hexdigest(File.read(tgzLocalFile)) != rs.md5
              new_rules=true
            end
          else
            #Cannot download rules from this source!!!!
            logit "  * Cannot download rules from this source!!! Exiting..."
            suspend_update=false
          end
        rescue => err
          logit "Error with the url #{rs.name} (#{err})"
          err.backtrace.each do |x|
            logit x
          end
          new_rules=true
          suspend_update = false
        end
      end

      db_version_last = RuleDbversion.last(:completed => true)
      if db_version_last.nil?
        sources_last=nil
      else
        sources_last    = db_version_last.sources.all(:order => :id)
      end
      new_rules=true if sources != sources_last

      #it is possible we have deleted or inserted new sources

      if new_rules and !suspend_update
        logit "We have new rules. Processing them." if config["verbose"]
        sources.each do |rs|
          next if suspend_update
          tgzLocalFile    = "#{config["cache_dir"]}/#{rs.name}.tgz"
          tgzLocalFileTmp = "#{config["cache_dir"]}/#{rs.name}-tmp.tgz"
          logit "Extracting #{tgzLocalFile}" if config["verbose"]
          dirExtract = "#{config["cache_dir"]}/#{rs.name}"
          `rm -rf #{dirExtract}; mkdir -p #{dirExtract}; tar xzf #{tgzLocalFile} -C #{dirExtract}`
        end


        dbVersion     = RuleDbversion.create(:timestamp => timenow, :completed => false, :sources => sources )
        so_rules_dir  = "#{config["so_rules_dir"]}/dbversion-#{dbVersion.id}"
        `mkdir -p #{so_rules_dir}`
        

        # We process first the so_rules
        sources.each do |rs|
          next if suspend_update
          logit "Processing #{rs.name} so_rules" if config["verbose"]
          dir = "#{config["cache_dir"]}/#{rs.name}"
          rs.so_rules.each do |rulesDir|
            logit "  * Directory: #{rulesDir}" if config["verbose"]
            if !Dir.exist?("#{dir}/#{rulesDir}")
              logit "    - Directory #{dir} does not exist. Ignored" if config["verbose"]
            else
              rulesDirectory = Dir.open("#{dir}/#{rulesDir}")
              count          = 0
              total          = rulesDirectory.to_a.size
              rulesDirectory.to_a.each do |file|
                count +=1
                next if file == "." or file == ".."
                logit "       - Reading #{file} ( #{(count*100.0/total).round(2)}% )" if config["verbose"]
                `cd #{dir}/#{rulesDir}/#{file} && if [ -f #{so_rules_dir}/snort-so_rules-#{file}.tar ]; then tar rf #{so_rules_dir}/snort-so_rules-#{file}.tar .; else tar cf #{so_rules_dir}/snort-so_rules-#{file}.tar .; fi`
              end
            end
          end
        end

        gen_msg_dir   = "#{config["gen_msg_dir"]}/dbversion-#{dbVersion.id}"
        `mkdir -p #{gen_msg_dir}`
        # We process the gen-msg files
        sources.each do |rs|
          next if suspend_update
          logit "Processing #{rs.name} gen-msg.map" if config["verbose"]
          dir = "#{config["cache_dir"]}/#{rs.name}"
          files = find(dir, "gen-msg.map")
          files.each do |f|
            logit "  * Found #{f}" if config["verbose"]
            `cat #{f} >> #{gen_msg_dir}/gen-msg.map`
          end
        end
        [ "2.9.8.3", "2.9.4.1", "2.9.4", "2.9.4.rc", "2.9.3.1", "2.9.2.2" ].each do |file|
          `if [ ! -f #{so_rules_dir}/snort-so_rules-#{file}.tar ]; then rm -f /tmp/.fake; touch /tmp/.fake; tar cf #{so_rules_dir}/snort-so_rules-#{file}.tar -C /tmp /tmp/.fake &>/dev/null; fi`
        end

        # Compressing the tar files
        so_rulesCompressed = Dir.open(so_rules_dir)
        so_rulesCompressed.to_a.each do |file|
          next if file == "." or file == ".."
          next unless file.ends_with? "tar"
          `gzip -q #{so_rules_dir}/#{file};`


          soRuleMatch = /^snort-so_rules-(?<version>[\d\.]+).tar$/.match(file)
          unless soRuleMatch.nil?
            so_versions = soRuleMatch[:version].split('.')

            if so_versions.length>2
              `[ ! -f #{so_rules_dir}/snort-so_rules-#{so_versions[0].to_s}.#{so_versions[1].to_s}.tar.gz ] && ln -s #{file}.gz #{so_rules_dir}/snort-so_rules-#{so_versions[0].to_s}.#{so_versions[1].to_s}.tar.gz`
            end          
          end
        end

        # Changing permisions to apache to integrate it in the system
        `[ -d #{so_rules_dir} ] && chown -R www-data.www-data #{so_rules_dir}`
        
        # Processing classification.config file.
        sources.each do |rs|
          next if suspend_update
          logit "Processing #{rs.name} classification.config" if config["verbose"]
          begin
            csFiles = find("#{config["cache_dir"]}/#{rs.name}", "classification.config")
            csFiles.each do |f|
              logit "  * Found #{f}" if config["verbose"]
              classificationFile = File.open(f)
              while classtypeLine = classificationFile.gets
                next if classtypeLine.starts_with?('#') || classtypeLine.starts_with?('\n')
                classtypeMatch = /^config classification:\s*(?<name>[^,]+)\s*,\s*(?<description>[^,]+)\s*,\s*(?<severity_id>[\d]+)$/.match(classtypeLine)
              
                unless classtypeMatch.nil?
                  rc2 = RuleCategory2.first(:name => classtypeMatch[:name], :dbversion_id =>dbVersion.id)
                  rc2 = RuleCategory2.create(:name=>classtypeMatch[:name], :dbversion_id => dbVersion.id) if rc2.nil?
                  rc2.update(:description => classtypeMatch[:description], :severity_id => classtypeMatch[:severity_id])
                end
              end
            end
          rescue => e
            logit "  * Classification file not founded" if config["verbose"]
          end
        end

        sources.each do |rs|
          next if suspend_update
          logit "Processing #{rs.name} rules" if config["verbose"]

          rs.search.each do |rulesDir|
            logit "  * Directory: #{rulesDir}" if config["verbose"]

            dir = "#{config["cache_dir"]}/#{rs.name}/#{rulesDir}"
            if !Dir.exist?(dir)
              logit "    - Directory #{dir} does not exist. Ignored" if config["verbose"]
            else
              Rule.transaction do |t|
                begin
                  rulesDirectory = Dir.open(dir)
                  pathRulesDir   = rulesDirectory.to_path
                  count          = 0
                  total          = rulesDirectory.to_a.size

                  rulesDirectory.to_a.each do |file|
                    count += 1
                    next if file == "." or file == ".."
                    next unless file =~ /\.rules$/

                    logit "       - Reading #{file} ( #{(count*100.0/total).round(2)}% )" if config["verbose"]
                    ruleFile = pathRulesDir + "/" + file
                    category1 = file.gsub(".rules","").strip.downcase
                    category1 = category1.gsub /#{rs.regexp_category1_ignore}/, "" unless rs.regexp_category1_ignore.nil?

                    category1_tmp = category1

                    unless config["category1_groups"].nil?
                      config["category1_groups"].each do |catgr|
                        unless /#{catgr["regexp"]}/.match(category1).nil?
                          category1_tmp = catgr["name"]
                          break
                        end
                      end
                    end

                    if category1_tmp!="deleted"
                      rc1 = RuleCategory1.first(:name => category1_tmp)
                      rc1 = RuleCategory1.create(:name=> category1_tmp) if rc1.nil?

                      category4=nil
                      category4_desc=nil
                      unless config["category4_groups"].nil?
                        config["category4_groups"].each do |catgr|
                          unless /#{catgr["regexp"]}/.match(category1_tmp).nil?
                            category4      = catgr["name"]
                            category4_desc = catgr["desc"]
                            break
                          end
                        end
                      end

                      category4="others" if category4.nil?
                      rc4 = RuleCategory4.first(:name => category4)
                      rc4 = RuleCategory4.create(:name=> category4) if rc4.nil?
                      rc4.update(:description => category4_desc) unless category4_desc.nil?

                      ruleFile = File.open(ruleFile)

                      while ruleLine = ruleFile.gets
                        ruleLine.chop!
                        ruleMatch = /^(?<disabled>[#]\s*)?(?<action>\w+)\s+(?<l3l4>(?<protocol>\w+)\s+(?<source_addr>[^\s]+)\s+(?<source_port>[^\s]+)\s+(?<separator>->|<>)\s+(?<target_addr>[^\s]+)\s+(?<target_port>[^\s]+)\s+)?\((?<rule>.+)\)\s*$/.match(ruleLine)
                        unless ruleMatch.nil?

                          #variables
                          unless ruleMatch[:protocol].nil?
                            vars = (ruleMatch[:source_addr] +" " +ruleMatch[:target_addr]).scan(/\$([\w_]*)/)
                            vars.each do |x|
                              var = RuleVariable.first(:name => x[0], :type=>RuleVariable::IPVAR)
                              var = RuleVariable.create(:name=> x[0], :type=>RuleVariable::IPVAR) if var.nil?
                            end
                            vars = (ruleMatch[:source_port] +" " +ruleMatch[:target_port]).scan(/\$([\w_]*)/)
                            vars.each do |x|
                              var = RuleVariable.first(:name => x[0], :type=>RuleVariable::PORTVAR)
                              var = RuleVariable.create(:name=> x[0], :type=>RuleVariable::PORTVAR) if var.nil?
                            end
                          end

                          sidRuleMatch = /sid:\s?(?<sid>\d+);/.match(ruleMatch[:rule])
                          unless sidRuleMatch.nil?
                            msgRuleMatch = /\s*msg:\s?"(?<msg>[^"]+)";/.match(ruleMatch[:rule])
                            unless msgRuleMatch.nil?
                              classtypeRuleMatch = /; classtype:.*(?<classtype>[^;]+);/.match(ruleMatch[:rule])
                              if classtypeRuleMatch.nil?
                                category2="unknown"
                              else
                                category2 = classtypeRuleMatch[:classtype].strip.downcase
                                category2 = category2.gsub /#{rs.regexp_category2_ignore}/, "" unless rs.regexp_category2_ignore.nil?
                              end

                              rc2 = RuleCategory2.first(:name => category2, :dbversion_id =>dbVersion.id)
                              rc2 = RuleCategory2.create(:name=>category2, :dbversion_id =>dbVersion.id) if rc2.nil?

                              rule_msg = msgRuleMatch[:msg].downcase
                              rule_msg = rule_msg.gsub /#{rs.regexp_category3_ignore}/, "" unless rs.regexp_category3_ignore.nil?
                              rule_msg = rule_msg.gsub /^#{category1} /, ""
                              category3=nil

                              unless config["category3_groups"].nil?
                                config["category3_groups"].each do |catgr|
                                  unless /#{catgr["regexp"]}/.match(rule_msg).nil?
                                    category3 = catgr["name"]
                                  end
                                end
                              end

                              if category3.nil?
                                category3RuleMatch = /([^ _-]*([ _-][^ _-]*)?([ _-][^ _-]*)?)/.match(rule_msg)
                                if category3RuleMatch.nil?
                                  category3="unknown"
                                else
                                  category3 = category3RuleMatch[0][0..63].strip
                                end
                              end

                              rc3 = RuleCategory3.first(:name => category3)
                              rc3 = RuleCategory3.create(:name=>category3) if rc3.nil?

                              revRuleMatch = /; rev:\s*(?<value>\d+);/.match(ruleMatch[:rule])
                              rev = revRuleMatch.nil? ? 0 : revRuleMatch[:value].to_i

                              gidRuleMatch = /; gid:\s*(?<value>\d+);/.match(ruleMatch[:rule])
                              gid = gidRuleMatch.nil? ? 1 : gidRuleMatch[:value].to_i

                              r = Rule.new()
                              r.rule_id         = sidRuleMatch[:sid].to_i
                              r.msg             = msgRuleMatch[:msg]
                              r.short_msg       = msgRuleMatch[:msg].gsub( /^#{rc1.name.upcase} /, '' )
                              r.category1_id    = rc1.id
                              r.category2_id    = rc2.id
                              r.category3_id    = rc3.id
                              r.category4_id    = rc4.id
                              r.protocol        = ruleMatch[:protocol]
                              r.source_addr     = ruleMatch[:source_addr]
                              r.source_port     = ruleMatch[:source_port]
                              r.target_addr     = ruleMatch[:target_addr]
                              r.target_port     = ruleMatch[:target_port]
                              r.rev             = rev.to_i
                              r.gid             = gid.to_i
                              r.dbversion_id    = dbVersion.id
                              r.rule            = ruleMatch[:rule]
                              r.source_id       = rs.id
                              r.default_enabled = ruleMatch[:disabled].nil?

                              #We need to discover if this rule is new or modified.
                              r.is_deprecated = false
                              if db_version_last.nil?
                                r.is_new      = true
                                r.is_modified = false
                              else
                                rlast = Rule.last(:rule_id => r.rule_id, :gid => r.gid, :dbversion => db_version_last)
                                if rlast.nil?
                                  r.is_new      = true
                                  r.is_modified = false
                                else
                                  r.is_new      = false
                                  if r.rev != rlast.rev
                                    r.is_modified = true
                                  else
                                    r.is_modified = false
                                  end
                                end
                              end

                              logit "    - rule msg: #{r.short_msg}" if config["verbose"]

                              if r.save
                                #METADATA
                                metadataRuleMatch = /; metadata:\s*(?<value>[^;]+);/.match(ruleMatch[:rule])
                                unless metadataRuleMatch.nil?
                                  metadataRuleMatch[:value].split(/,\s*/).each do |x|
                                    policyRuleMatch = /^policy\s+(?<name>[^ ]+)\s+(?<action>[^ ]+)/.match(x)
                                    if policyRuleMatch.nil?
                                      serviceRuleMatch = /^service\s+(?<name>[^;]+)\s*/.match(x)
                                      if serviceRuleMatch.nil?
                                        impactRuleMatch = /^impact_flag\s+(?<name>[^;]+)\s*/.match(x)
                                        unless impactRuleMatch.nil?
                                          impact = Impact.first(:name => impactRuleMatch[:name])
                                          impact = Impact.create(:name=> impactRuleMatch[:name]) if impact.nil?
                                          RuleImpact.create(:rule_id=>r.id, :impact_id=>impact.id)
                                        end
                                      else
                                        service = Service.first(:name => serviceRuleMatch[:name])
                                        service = Service.create(:name=> serviceRuleMatch[:name]) if service.nil?
                                        RuleService.create(:rule_id=>r.id, :service_id=>service.id)
                                      end
                                    else
                                      policy = Policy.first(:name => policyRuleMatch[:name])
                                      policy = Policy.create(:name=> policyRuleMatch[:name]) if policy.nil?
                                      action = RuleAction.first(:name=>policyRuleMatch[:action])
                                      RulePolicy.create(:rule_id=>r.id, :policy_id=>policy.id, :action_id=>action.id) unless action.nil?
                                    end
                                  end
                                end

                                #REFERENCE
                                referenceSplit = ruleMatch[:rule].split(/;\s*reference:\s*/)
                                referenceSplit.each_with_index do |x,i|
                                  if i>0
                                    referenceRuleMatch = /^(?<name>[^,]+)\s*,\s*(?<url>[^;]+)\s*/.match(x)
                                    unless referenceRuleMatch.nil?
                                      reference = Rbreference.first(:name => referenceRuleMatch[:name])
                                      reference = Rbreference.create(:name => referenceRuleMatch[:name]) if reference.nil?
                                      RuleRbreference.create(:rule_id=>r.id, :reference_id=>reference.id, :url=>referenceRuleMatch[:url])
                                    end
                                  end
                                end

                                #FLOWBITS
                                flowbitSplit = ruleMatch[:rule].split(/;\s*flowbits:.*/)
                                flowbitSplit.each_with_index do |x,i|
                                  if i>0
                                    flowbitRuleMatch = /^(?<action>[^,; ]+)\s*(,\s*(?<state>[^,; ]+)\s*(,\s*(?<group>[,; ]))?)?\s*/.match(x)
                                    unless flowbitRuleMatch.nil?
                                      flowbit = Flowbit.first(:name => flowbitRuleMatch[:action])
                                      flowbit = Flowbit.create(:name => flowbitRuleMatch[:action]) if flowbit.nil?
                                      flowbit_state = nil
                                      flowbit_group = nil
                                      unless flowbitRuleMatch[:state].nil?
                                        flowbit_state = FlowbitState.first(:name => flowbitRuleMatch[:state])
                                        flowbit_state = FlowbitState.create(:name => flowbitRuleMatch[:state]) if flowbit_state.nil?
                                        unless flowbitRuleMatch[:group].nil?
                                          flowbit_group = FlowbitGroup.first(:name => flowbitRuleMatch[:group])
                                          flowbit_group = FlowbitGroup.create(:name => flowbitRuleMatch[:group]) if flowbit_group.nil?
                                        end
                                      end
                                      RuleFlowbit.create(:rule_id=>r.id, :flowbit_id=>flowbit.id, :state=>flowbit_state, :group=>flowbit_group )
                                    end
                                  end
                                end
			     
                              else
                                logit "The rule has not been saved -> Rule: #{ruleLine}; Errors: #{r.errors.inspect}" if config["verbose"]
                              end
                            else
                              logit "MSG not found -> #{ruleLine}" if config["verbose"]
                            end
                          else
                            logit "SID not found -> #{ruleLine}" if config["verbose"]
                          end
                        else
                          #logit "rule line doesn't match -> ruleLine" if config["verbose"]
                        end
                      end
                      ruleFile.close
                    end
                  end

                  rulesDirectory.close

                rescue DataObjects::Error => e
                  logit "An error has finalized the transaction. #{e.to_s}. Rolling back!"
                  new_rules=false
                  suspend_update = true
                  p e
                  t.rollback
                end
              end
            end
          end
        end

        if new_rules and !dbVersion.nil? and !suspend_update and !db_version_last.nil?
          Rule.transaction do |t|
            begin
              db_version_last.rules.each do |r|
                r_new = Rule.last(:rule_id => r.rule_id, :gid => r.gid, :dbversion => dbVersion)
                r.update(:is_deprecated => true) if r_new.nil?
              end              
            rescue DataObjects::Error => e
              logit "An error has finalized the transaction. #{e.to_s}. Rolling back!"
              new_rules=false
              suspend_update = true
              p e
              t.rollback
            end
          end
        end

        if new_rules and !dbVersion.nil? and !suspend_update
          dbVersion.completed              = true;
          dbVersion.rules_count            = dbVersion.rules.count
          dbVersion.rules_new_count        = dbVersion.rules.count(:is_new=>true)
          dbVersion.rules_modified_count   = dbVersion.rules.count(:is_modified=>true)
          dbVersion.rules_deprecated_count = db_version_last.rules.count(:is_deprecated => true) unless db_version_last.nil?
          
          dbVersion.save
          sources.each do |rs|
            rs.update(:md5 => Digest::MD5.hexdigest(File.read("#{config["cache_dir"]}/#{rs.name}.tgz")), :timestamp => timenow)
          end
        end
      end
      logit "Exiting successfully" if config["verbose"]

    rescue => global_err
      logit "Error with updating rules (ERROR: #{global_err})"
    end

    def self.find(dir, filename="*.*", subdirs=true)
      Dir[ subdirs ? File.join(dir.split(/\\/), "**", filename) : File.join(dir.split(/\\/), filename) ]
    end

    def self.logit(msg)
      STDOUT.puts "#{msg}"
    end

    def self.download_file(url, local_file)
      
      File.delete(local_file) if File.exists?(local_file)
      
      uri = URI.parse(url)   
      if Setting.proxy?
        proxy_class = Net::HTTP::Proxy(Setting.find('proxy_address'), Setting.find('proxy_port'), Setting.find('proxy_user'), Setting.find('proxy_password'))
        http = proxy_class.new(uri.host, uri.port)
      else
        http = Net::HTTP.new(uri.host, uri.port)
      end
      
      if uri.scheme == "https"
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      #
      resp = http.get(url)
      #
      if resp.is_a?(Net::HTTPOK)
        open(local_file, "wb") do |file|
          file.write(resp.body)
        end
      end
      #

      url = ("http://" + url) if !url.start_with?"http://" and !url.start_with?"https://" and !url.start_with?"ftp://"

      writeOut = open(local_file, "wb")
      if Setting.proxy? and Setting.find('proxy_address').present?
         proxy_port = Setting.find('proxy_port').to_i
         proxy_port = 8080 if proxy_port<=0
         proxy_addr = Setting.find('proxy_address')
         proxy_addr = ("http://" + proxy_addr) if !proxy_addr.start_with?"http://" and !proxy_addr.start_with?"https://"
         proxy = URI.parse(proxy_addr +":" +proxy_port.to_s)
         if Setting.find('proxy_user').present?
           writeOut.write(open(url, :proxy_http_basic_authentication => [proxy, Setting.find('proxy_user'), Setting.find('proxy_password')], :ssl_verify_mode=>OpenSSL::SSL::VERIFY_NONE).read)
         else
           writeOut.write(open(url, :proxy=>proxy, :ssl_verify_mode=>OpenSSL::SSL::VERIFY_NONE).read)
         end
      else
         writeOut.write(open(url, :proxy=>false, :ssl_verify_mode=>OpenSSL::SSL::VERIFY_NONE).read)
      end
      writeOut.close
    end
  end
end
