class NoteMailer < ActionMailer::Base

  def new_note(note)
    @note = note

    @item = case note.class.to_s
      when 'Note'
        @note.event
      when 'EventFilteringNote'
        @note.event_filtering
      when 'ReputationNote'
        @note.reputation
      when 'RuleNote'
        @note.rule
      end

    @emails = []
    
    User.all.each do |user|
      @emails << "#{user.name} <#{user.email}>" if user.accepts_note_notifications?(@item)
    end

    @from = (Setting.email? ? Setting.find(:email) : "admin@onshore.com")

    mail(:to => @emails, :from => @from, :subject => "[onGuard SIM] New #{@item.class} Note Added")
  end

end