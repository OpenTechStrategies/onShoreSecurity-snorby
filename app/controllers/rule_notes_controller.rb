class RuleNotesController < ApplicationController
  before_filter :require_administrative_privileges, :only => [:destroy, :edit, :update]
  before_filter :find_rule, :only => [:create, :new]

  def find_rule
    @rule = Rule.get(params[:rule_id])
    @user = User.current_user
  end

  def new
  end

  def create
    @note = @rule.notes.create({ :user => @user, :body => params[:body] })
    if @note.save
      Delayed::Job.enqueue(Snorby::Jobs::NoteNotification.new(self.class, @note.id))
    end
  end

  def destroy
    @note = RuleNote.get(params[:id])
    @rule = @note.rule
    @note.destroy
  end

end