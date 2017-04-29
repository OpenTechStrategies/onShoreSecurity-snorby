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

module Snorby
  module Jobs
    class GeoipUpdatedbJob < Struct.new(:verbose)
      def perform
        uri = if Snorby::CONFIG.has_key?(:geoip_uri)
          URI(Snorby::CONFIG[:geoip_uri])
        else
          URI("http://geolite.maxmind.com/download/geoip/database/GeoLiteCountry/GeoIP.dat.gz")
        end
        update(uri, 'tmp/tmp-snorby-geoip.dat', 'config/snorby-geoip.dat')

        uri = if Snorby::CONFIG.has_key?(:geoip_uri_city)
          URI(Snorby::CONFIG[:geoip_uri_city])
        else
          URI("http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz")
        end
        update(uri, 'tmp/tmp-snorby-geoip-city.dat', 'config/snorby-geoip-city.dat')

        #Tx this to all sensor with reputation proprocessor enabled.
        p "Updating sensors geoip database"
        Sensor.all(:virtual_sensor => true).select {|x| begin x.chef_node[:redBorder][:snort][:preprocessors][:reputation][:mode] rescue false end }.each do |x|
          p "Updating #{x.name}"
          begin 
            x.uploadGeoIp(true)
          rescue => ex
            p ex 
            p "Cannot send geo database to #{x.name}"
          end
        end
 
        Snorby::Jobs.geoip_update.destroy! if Snorby::Jobs.geoip_update?
        Delayed::Job.enqueue(Snorby::Jobs::GeoipUpdatedbJob.new(false), :priority => 25, :run_at => 1.week.from_now);
      rescue => e
        puts e
        puts e.backtrace
      end

      def update(uri, tmp_file, local_file)
        p "Updating #{local_file} from #{uri.to_s}"
        if Setting.proxy?
          proxy_class = Net::HTTP::Proxy(Setting.find('proxy_address'), Setting.find('proxy_port'), Setting.find('proxy_user'), Setting.find('proxy_password'))
          http = proxy_class.new(uri.host, uri.port)
          resp = http.get_response(uri)
        else
          resp = Net::HTTP.get_response(uri)
        end

        if resp.is_a?(Net::HTTPOK)
          open(tmp_file, "wb") do |file|
            gz = Zlib::GzipReader.new(StringIO.new(resp.body.to_s)) 
            file.write(gz.read)
          end
        end

        if File.exists?(tmp_file)
          FileUtils.mv(tmp_file, local_file, :force => true)
        end
      end
    end
  end
end
