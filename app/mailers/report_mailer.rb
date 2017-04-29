class ReportMailer < ActionMailer::Base
  
  def daily_report(sids=nil, user=nil)
    @emails = []
    user.nil? ? 
      User.all(:admin => true, :daily => true).each { |u| @emails << "#{u.name} <#{u.email}>" } : 
      @emails << "#{user.name} <#{user.email}>"
    
    unless @emails.blank?
      report = Snorby::Report.build_report('yesterday', sids)
      attachments["onguard-daily-report.pdf"] = report[:pdf]
      mail(:to => @emails, :from => (Setting.email? ? Setting.find(:email) : "security@onshore.com"), :subject => "onGuard SIM Daily Report: #{report[:start_time].strftime('%A, %B %d, %Y')}")
    end
  end
  
  def weekly_report(sids=nil, user=nil)
    @emails = []
    user.nil? ? 
      User.all(:admin => true, :weekly => true).each { |u| @emails << "#{u.name} <#{u.email}>" } : 
      @emails << "#{user.name} <#{user.email}>"

    unless @emails.blank?
      report = Snorby::Report.build_report('last_week', sids)
      attachments["onguard-weekly-report.pdf"] = report[:pdf]
      mail(:to => @emails, :from => (Setting.email? ? Setting.find(:email) : "security@onshore.com"), :subject => "onGuard SIM Weekly Report: #{report[:start_time].strftime('%A, %B %d, %Y %I:%M %p')} - #{report[:end_time].strftime('%A, %B %d, %Y %I:%M %p')}")
    end
  end

  def monthly_report(sids=nil, user=nil)
    @emails = []
    user.nil? ? 
      User.all(:admin => true, :monthly => true).each { |u| @emails << "#{u.name} <#{u.email}>" } : 
      @emails << "#{user.name} <#{user.email}>"

    unless @emails.blank?
      report = Snorby::Report.build_report('last_month', sids)
      attachments["onguard-monthly-report.pdf"] = report[:pdf]
      mail(:to => @emails, :from => (Setting.email? ? Setting.find(:email) : "security@onshore.com"), :subject => "onGuard SIM Monthly Report: #{report[:start_time].strftime('%A, %B %d, %Y %I:%M %p')} - #{report[:end_time].strftime('%A, %B %d, %Y %I:%M %p')}")
    end
  end

  def yearly_report(sids=nil, user=nil)
    @emails = []
    user.nil? ? 
      User.all(:admin => true, :yearly => true).each { |u| @emails << "#{u.name} <#{u.email}>" } : 
      @emails << "#{user.name} <#{user.email}>"

    unless @emails.blank?
      report  = Snorby::Report.build_report('last_year', sids)
      attachments["onguard-yearly-report.pdf"] = report[:pdf]
      mail(:to => @emails, :from => (Setting.email? ? Setting.find(:email) : "security@onshore.com"), :subject => "onGuard SIM Yearly Report: #{report[:start_time].strftime('%A, %B %d, %Y %I:%M %p')} - #{report[:end_time].strftime('%A, %B %d, %Y %I:%M %p')}")
    end
  end
end

