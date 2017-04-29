class EventMailer < ActionMailer::Base
  
  def event_information(event, emails, subject, note, user)
    @event = event
    @user = user
    @emails = emails.split(',')
    @note = note

    @from = (Setting.email? ? Setting.find(:email) : "admin@onshore.com")
    
    mail(:to => @emails, :from => @from, :subject => "[onGuard SIM Event] #{subject}")
  end
  
end
