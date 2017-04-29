#!script/rails runner
#
# Copyright (c) 2011 redBorder Networks
# Authors:
# 	Pablo Nebrera Herrera  pablonebrera@eneotecnologia.com
#	  Juan Jesus Prieto:     jjprieto@eneotecnologia.com
#	  Jose Antonio Parra:    japarra@eneotecnologia.com
#
#  Description:
#	Utilities to work with the manager cluster
#
###########################################################################################################

module Snorby
  class Cluster
    
    attr_reader :mode, :services, :service, :members, :drbd

    def mode
      `cat /etc/rb_sysconf.conf|grep "^sys_ha_mode=" | sed 's/^sys_ha_mode=//'`.chomp
    end

    def local_ip
      `cat /etc/rb_sysconf.conf|grep "^net_ip=" | sed 's/^net_ip=//'`.chomp
    end

    def local_hostname
      `cat /etc/rb_sysconf.conf|grep "^sys_hostname=" | sed 's/^sys_hostname=//'`.chomp
    end

    def remote_ip
      `cat /etc/rb_sysconf.conf|grep "^sys_ha_remote_ip=" | sed 's/^sys_ha_remote_ip=//'`.chomp
    end

    def remote_hostname
      `cat /etc/rb_sysconf.conf|grep "^sys_ha_remote_hostname=" | sed 's/^sys_ha_remote_hostname=//'`.chomp
    end

    def virtual_ip
      `cat /etc/rb_sysconf.conf|grep "^sys_ha_virtual_ip=" | sed 's/^sys_ha_virtual_ip=//'`.chomp
    end

    def member_status
      `sudo clustat |grep "^Member Status:"|awk '{print $3}'`.chomp
    end

    def services
      result = []
      services=["mysql", "httpd", "couchdb", "rabbitmq-server", "chef-solr", "chef-expander", "chef-server", "chef-client", "rb-workers"]
      services.each do |s|
        hash = {}
        hash[:name] = s
        serviceout = if s == "mysql"
          `pidof mysqld &>/dev/null; echo $?`.chomp
        elsif s == "rabbitmq-server"
          #`sudo /etc/init.d/#{s} status &>/dev/null; echo $?`.chomp
          `if [ -f /var/lock/subsys/rabbitmq-server ]; then echo -n 0; else echo -n 1; fi`.chomp
        else
          `/etc/init.d/#{s} status &>/dev/null; echo $?`.chomp
        end

        hash[:status] = if serviceout == "0"
          "OK"
        else
          "DOWN"
        end

        result << hash

      end

      result

    end
 
    def service
      result = []
      serviceout = `sudo /usr/sbin/clustat |grep -A 100 "Service Name" | grep -v "Service Name"`.chomp
      serviceout.each_line do |s|
        match = /^\s*service:(?<name>[^\s]+)\s+(?<owner>[^\s]+)\s+(?<status>[^\s]+)\s*(?<freeze>\[Z\])?/.match(s)
        unless match.nil?
          hash = {}
          hash[:name]   = match[:name]
          hash[:owner]  = match[:owner]
          hash[:status] = match[:status]
          hash[:freeze] = !match[:freeze].nil?
          result << hash
        end
      end
      result
    end
 
    def members
      result = []
      serviceout = `sudo /usr/sbin/clustat |grep -A 3 "Member Name" | grep -v "Member Name"`.chomp
      serviceout.each_line do |s|
        match = /^\s*(?<name>[^\s]+)\s+(?<id>[^\s]+)\s+(?<status>.+)\s*$/.match(s)
        unless match.nil?
          id = match[:id].to_i
          if id > 0 and match[:name] != "UNKNOWNNODE"
            hash = {}
            hash[:name]   = match[:name]
            hash[:id]     = id
            hash[:status] = match[:status]
            result << hash
          end
        end
      end

      result
    
    end
 
    def drbd
      hash = {}
      hash[:cstate] = `drbdadm cstate shared`
      var = ["dstate", "role"]
      var.each do |s|
        state = `drbdadm #{s} shared`
        match = /^(?<local>[^\s]+)\/(?<remote>[^\s]+)$/.match(state)
        unless match.nil?
          hash[s.to_sym] = {}
          hash[s.to_sym][:local]  = match[:local]
          hash[s.to_sym][:remote] = match[:remote]
        end
      end

      hash
    
    end
  end
end
