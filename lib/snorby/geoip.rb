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

require 'geoip'

module Snorby
  module Geoip
   
    PATH = File.join(Rails.root.to_s, 'config', 'snorby-geoip.dat')
    PATH2 = File.join(Rails.root.to_s, 'config', 'snorby-geoip-city.dat')

    FAKE_DATA = {
      :country_code2 => "N/A" 
    }
    
    def self.database?
      return false unless File.exists?(PATH)
      return false if File.zero?(PATH)
      File.open(PATH)
    end

    def self.databaseCity?
      return false unless File.exists?(PATH2)
      return false if File.zero?(PATH2)
      File.open(PATH2)
    end

    def self.lookup(ip)
      database = self.database?
      return FAKE_DATA unless database
      lookup = GeoIP.new(database).country(ip)
      lookup.to_hash
    rescue ArgumentError => e
      {}
    end

    def self.city(ip)
      databaseCity = self.databaseCity?
      return FAKE_DATA unless databaseCity
      city = GeoIP.new(databaseCity).city(ip)
      if city.nil?
        {}
      else
        city.to_hash
      end
    rescue ArgumentError => e
      {}
    end

    def self.locate(colection)
      var = {}
      colection.each do |x|
        l = city(x)
        var[x] = l unless l.empty?
      end
      var
    end

    def self.latlong(colection)
      var = []
      colection.each do |x|
        l = city(x)
        unless l.empty?
          desc = ""
          l.each do |k,v|
            desc += "<b>#{k.to_s}:</b> #{v.to_s}<br/>" if k==:ip or k==:latitude or k==:longitude or k==:country_name or k==:city_name or k==:timezone
          end
          var << {"lat" => l[:latitude], "lng" => l[:longitude], "description" => "<html>#{desc}</html>"}
        end
      end
      var
    end
  end
end
