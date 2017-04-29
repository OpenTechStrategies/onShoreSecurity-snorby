# Snorby - All About Simplicity.
# 
# Copyright (c) 2010 Dustin Willis Webber (dustin.webber at gmail.com)
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

require 'snorby/jobs/alert_notifications'
require 'snorby/jobs/cache_helper'
require 'snorby/jobs/daily_cache_job'
require 'snorby/jobs/event_mailer_job'
require 'snorby/jobs/note_notification'
require 'snorby/jobs/mass_classification'
require 'snorby/jobs/sensor_cache_job'
require 'snorby/jobs/compilation_job'
require 'snorby/jobs/sensor_update_dbversion_job'
require 'snorby/jobs/rollback_job'
require 'snorby/jobs/delete_sensor_job'
require 'snorby/jobs/delete_dbversion_job'
require 'snorby/jobs/main'

module Snorby

  module Jobs

    def self.find
      Delayed::Backend::DataMapper::Job
    end

    def self.run(obj, priority=1, time=Time.now.to_datetime)
      Delayed::Job.enqueue(obj, :priority => priority, :run_at => time)
    end

    def self.start
      Jobs::Main.new(false).perform unless Jobs.main?
      Jobs::SensorCacheJob.new(false).perform unless Jobs.sensor_cache?
      Jobs::DailyCacheJob.new(false).perform unless Jobs.daily_cache?
      Jobs::GeoipUpdatedbJob.new(false).perform if (Setting.geoip? && !Jobs.geoip_update?)
      Jobs::RuleUpdatedbJob.new(false).perform unless Jobs.rule_update?
      Jobs::SnmpJob.new(false).perform unless Jobs.snmp?
    end

    def self.main
      Snorby::Jobs.find.first(:handler.like => "%!ruby/struct:Snorby::Jobs::Main%")
    end

    def self.sensor_cache
      Snorby::Jobs.find.first(:handler.like => "%!ruby/struct:Snorby::Jobs::SensorCacheJob%")
    end

    def self.daily_cache
      Snorby::Jobs.find.first(:handler.like => "%!ruby/struct:Snorby::Jobs::DailyCacheJob%")
    end
    
    def self.geoip_update
      Snorby::Jobs.find.first(:handler.like => "%!ruby/struct:Snorby::Jobs::GeoipUpdatedbJob%")
    end

    def self.rule_update
      Snorby::Jobs.find.first(:handler.like => "%!ruby/struct:Snorby::Jobs::RuleUpdatedbJob%")
    end

    def self.snmp
      Snorby::Jobs.find.first(:handler.like => "%!ruby/struct:Snorby::Jobs::SnmpJob%")
    end

    def self.compilation
      Snorby::Jobs.find.first(:handler.like => "%!ruby/struct:Snorby::Jobs::CompilationJob%")
    end

    def self.sensor_update_dbversion
      Snorby::Jobs.find.first(:handler.like => "%!ruby/struct:Snorby::Jobs::SensorUpdateDbversionJob%")
    end

    def self.rollback
      Snorby::Jobs.find.first(:handler.like => "%!ruby/struct:Snorby::Jobs::RollbackJob%")
    end

    def self.delete_sensor
      Snorby::Jobs.find.first(:handler.like => "%!ruby/struct:Snorby::Jobs::DeleteSensorJob%")
    end

    def self.main?
      !Snorby::Jobs.find.first(:handler.like => "%!ruby/struct:Snorby::Jobs::Main%").blank?
    end

    def self.sensor_cache?
      !Snorby::Jobs.find.first(:handler.like => "%!ruby/struct:Snorby::Jobs::SensorCacheJob%").blank?
    end

    def self.daily_cache?
      !Snorby::Jobs.find.first(:handler.like => "%!ruby/struct:Snorby::Jobs::DailyCacheJob%").blank?
    end
    
    def self.geoip_update?
      !Snorby::Jobs.find.first(:handler.like => "%!ruby/struct:Snorby::Jobs::GeoipUpdatedbJob%").blank?
    end    

    def self.rule_update?
      !Snorby::Jobs.find.first(:handler.like => "%!ruby/struct:Snorby::Jobs::RuleUpdatedbJob%").blank?
    end

    def self.snmp?
      !Snorby::Jobs.find.first(:handler.like => "%!ruby/struct:Snorby::Jobs::SnmpJob%").blank?
    end

    def self.compilation?
      !Snorby::Jobs.find.first(:handler.like => "%!ruby/struct:Snorby::Jobs::CompilationJob%").blank?
    end

    def self.sensor_update_dbversion?
      !Snorby::Jobs.find.first(:handler.like => "%!ruby/struct:Snorby::Jobs::SensorUpdateDbversionJob%").blank?
    end

    def self.delete_dbversion?
      !Snorby::Jobs.find.first(:handler.like => "%!ruby/struct:Snorby::Jobs::DeleteDbversionJob%").blank?
    end

    def self.rollback?
      !Snorby::Jobs.find.first(:handler.like => "%!ruby/struct:Snorby::Jobs::RollbackJob%").blank?
    end

    def self.delete_sensor?
      !Snorby::Jobs.find.first(:handler.like => "%!ruby/struct:Snorby::Jobs::DeleteSensorJob%").blank?
    end

    def self.main_running?
      return true if Jobs.main? && Jobs.main.locked_at
      false
    end

    def self.sensor_caching?
      return true if Jobs.sensor_cache? && Jobs.sensor_cache.locked_at
      false
    end

    def self.daily_caching?
      return true if Jobs.daily_cache? && Jobs.daily_cache.locked_at
      false
    end

    def self.geoip_updating?
      return true if Jobs.geoip_update? && Jobs.geoip_update.locked_at
      false      
    end

    def self.rule_updating?
      return true if Jobs.rule_update? && Jobs.rule_update.locked_at
      false
    end

    def self.snmp_caching?
      return true if Jobs.snmp? && Jobs.snmp.locked_at
      false      
    end

    def self.compilation_running?
      return true if Jobs.compilation? && Jobs.compilation.locked_at
    end

    def self.updating_dbversion?
      return true if Jobs.sensor_update_dbversion? && Jobs.sensor_update_dbversion.locked_at
    end

    def self.rollback_running?
      return true if Jobs.rollback? && Jobs.rollback.locked_at
    end

    def self.delete_sensor_running?
      return true if Jobs.delete_sensor? && Jobs.delete_sensor.locked_at
    end

    def self.caching?
      return true if (Jobs.sensor_caching? || Jobs.daily_caching? || Jobs.snmp_caching?)
      false
    end
    
    def self.reset_counters
      Sensor.all.each do |sensor|
        sensor.update(:events_count => Event.all(:sid => sensor.sid).count)
      end
      Signature.all.each do |sig|
        sig.update(:events_count => Event.all(:sig_id => sig.sig_id).count)
      end
      Classification.all.each do |classification|
        classification.update(:events_count => Event.all(:classification_id => classification.id).count)
      end
      Severity.all.each do |sev|
        sev.update(:events_count => Event.all(:"signature.sig_priority" => sev.sig_id).count)
      end
      nil
    end

    def self.reset_cache(type, verbose=true)
      case type.to_sym
      when :sensor
        Cache.all.destroy!
        Snorby::Jobs::SensorCacheJob.new(verbose).perform
      when :daily
        DailyCache.all.destroy!
        Snorby::Jobs::DailyCacheJob.new(verbose).perform
      when :all
        Cache.all.destroy!
        DailyCache.all.destroy!
        Snorby::Jobs::SensorCacheJob.new(verbose).perform
        Snorby::Jobs::DailyCacheJob.new(verbose).perform
      end
    end

    def self.run_now!
      Delayed::Job.enqueue(Snorby::Jobs::Main.new(false), 
      :priority => 1, :run_at => Time.now.to_datetime + 5.seconds)

=begin
      Delayed::Job.enqueue(Snorby::Jobs::SensorCacheJob.new(false), 
      :priority => 5, :run_at => Time.now.to_datetime + 5.second)

      Delayed::Job.enqueue(Snorby::Jobs::DailyCacheJob.new(false), 
      :priority => 10, :run_at => Time.now.tomorrow.to_datetime.beginning_of_day)

      Delayed::Job.enqueue(Snorby::Jobs::SnmpJob.new(false), 
      :priority => 20, :run_at => Time.now.to_datetime + 5.second)
=end
    end

    def self.force_sensor_cache
      if Jobs.sensor_cache?
        Jobs.sensor_cache.update(:run_at => Time.now.to_datetime + 5.second)
      else
        Delayed::Job.enqueue(Snorby::Jobs::SensorCacheJob.new(false), 
          :priority => 5, :run_at => Time.now.to_datetime + 5.second)
      end
    end

    def self.force_rule_update
      if Jobs.rule_update?
        Jobs.rule_update.update(:run_at => DateTime.now + 5.second)
      else
        Delayed::Job.enqueue(Snorby::Jobs::RuleUpdatedbJob.new(false), :priority => 15, :run_at => DateTime.now + 10.second)
      end
    end

    def self.clear_cache(are_you_sure=false)
      if are_you_sure
        Cache.all.destroy!
        DailyCache.all.destroy!
      end
    end

  end
end
