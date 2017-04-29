class DbversionsController < ApplicationController

  before_filter :require_administrative_privileges
  helper_method :sort_column, :sort_direction

  def index
    params[:sort] = sort_column
    params[:direction] = sort_direction
    params[:dbversion] ||= Hash.new
    params[:dbversion][:completed] = true 
    @dbversions = RuleDbversion.sorty(params)
    @first_ruledbversion_id = RuleDbversion.first(:completed => true).id
    respond_to do |format|
      format.html {render :layout => true}
      format.js
    end
  end

  def new_source
    @source = RuleSource.new 
    render :layout => false
  end
  
  def create_source
    @source = RuleSource.create(params[:rule_source])
    redirect_to dbversions_path
  end
 
  def edit_source
    @source = RuleSource.get!(params[:id])
    render :layout => false
  end
  
  def update_source
    @source = RuleSource.get!(params[:id])
    @source.update(params[:rule_source])
    redirect_to dbversions_path
  end
  
  def destroy_source
    @source = RuleSource.get!(params[:id])
    @source.destroy
    flash[:notice] = "Source successfully deleted."
    redirect_to dbversions_path
  end

  def delete_rules
    if Snorby::Jobs.delete_dbversion?
      flash[:notice] = "There is another deleting rules' version job in progress."
    else 
      Delayed::Job.enqueue(Snorby::Jobs::DeleteDbversionJob.new(params[:dbversion_id], true), :priority => 10, :run_at => Time.now + 10.seconds)
      flash[:notice] = "Delete rules' version has been enqueue."
    end
    redirect_to dbversions_path
  end
  
  def show
    @dbversion = RuleDbversion.get(params[:id])
  end

  def update_sources
    RuleSource.all.each do |source|
      if params[:sources].has_key?(source.id.to_s) and params[:sources][source.id.to_s].has_key?("enable")
        source.update(:enable => true, :code => params[:sources][source.id.to_s][:code])
      else
        source.update(:enable => false)
      end
    end
  end

  def update_sensors
    @dbversion = RuleDbversion.get(params[:dbversion_id])
    @dbversion.update_sensors(params[:delayed].present?) unless @dbversion.nil?
    redirect_to dbversions_path
  end

  def force_update
    Snorby::Jobs.force_rule_update
    redirect_to dbversions_path
  end

  def stats
    @axis = RuleDbversion.all(:order => [:timestamp.desc], 
                              :limit => 10, 
                              :completed => true).map{|d| "'#{d.timestamp.strftime('%m/%d/%Y')}'"}.reverse.join(',')
    @data = RuleDbversion.all(:order => [:timestamp.desc], :limit => 10, :completed => true).map{|d| d.rules_count}.reverse

    render :layout => false
  end
  
  private

  def sort_column
    return :id unless params.has_key?(:sort)
    return params[:sort].to_sym if RuleDbversion::SORT.has_key?(params[:sort].to_sym)
    :id
  end
  
  def sort_direction
    %w[asc desc].include?(params[:direction].to_s) ? params[:direction].to_sym : :desc
  end

end
