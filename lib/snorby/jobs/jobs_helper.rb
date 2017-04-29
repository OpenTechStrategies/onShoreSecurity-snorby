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
    module JobsHelper
      require 'logger'
      
      def logit(msg, show_sensor=true)
        job_logit = Logger.new ('log/' + (self.class.name.split('::').last || 'job') + '.log')
        
        if show_sensor
          job_logit.error "#{self.class} Sensor #{@sensor.sid}: #{msg}" if verbose
        else
          job_logit.error "#{self.class}#{msg}" if verbose
        end

      end
      
    end
  end
end    
      
