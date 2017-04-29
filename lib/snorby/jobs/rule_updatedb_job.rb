module Snorby
  module Jobs
    class RuleUpdatedbJob < Struct.new(:verbose)      
      def perform
        Snorby::RulesUpdate.start(false)
        Snorby::Jobs.rule_update.destroy! if Snorby::Jobs.rule_update?
        Delayed::Job.enqueue(Snorby::Jobs::RuleUpdatedbJob.new(false), :priority => 25, :run_at => 1.week.from_now.beginning_of_day)
      rescue => e
        puts e
        puts e.backtrace
      end
    end
  end
end
