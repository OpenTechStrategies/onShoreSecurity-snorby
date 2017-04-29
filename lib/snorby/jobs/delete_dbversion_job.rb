module Snorby
  module Jobs
    class DeleteDbversionJob < Struct.new(:dbversion_id, :verbose)

      include Snorby::Jobs::CacheHelper

      def perform

        dbversion = RuleDbversion.get(dbversion_id)
        
        unless dbversion.nil?
          begin
            dbversion.destroy_slowly
          rescue => e
            logit "#{e}"
          end
        end
      end
    end
  end
end