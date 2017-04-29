require 'snorby/model'

class ClassificationsController < ApplicationController

  before_filter :require_administrative_privileges

  def index
    @classifications = Classification.all.page(params[:page].to_i, :per_page => @current_user.per_page_count, :order => [:id.asc])

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @classifications }
    end
  end

  def show
    @classification = Classification.get(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @classification }
    end
  end

  def new
    @classification = Classification.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @classification }
    end
  end

  def edit
    @classification = Classification.get(params[:id])
  end

  def create
    @classification = Classification.new(params[:classification])

    respond_to do |format|
      if @classification.save
        format.html { redirect_to(classifications_url, :notice => 'Classification was successfully created.') }
        format.xml  { render :xml => @classification, :status => :created, :location => @classification }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @classification.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    @classification = Classification.get(params[:id])

    respond_to do |format|
      if @classification.update(params[:classification])
        format.html { redirect_to(classifications_url, :notice => 'Classification was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @classification.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @classification = Classification.get(params[:id])
    @classification.destroy!

    respond_to do |format|
      format.html { redirect_to(classifications_url) }
      format.xml  { head :ok }
    end
  end

  def auto
    @auto_classifications = AutoClassification.all(:order => [:position.asc])
  end

  def new_auto
    @auto_classification = AutoClassification.new
    render :layout => false
  end

  def create_auto

    params.delete_if{|k, v| v.blank?}

    options = {:classification_id => params[:classification_id]}
    options.merge!({:sid => params[:sid]}) if params[:sid]
    options.merge!({:ip_src => params[:ip_src]}) if params[:ip_src]
    options.merge!({:ip_dst => params[:ip_dst]}) if params[:ip_dst]

    if !options[:classification_id].nil? and options.size <= 1
      #no ha especificado los parámetros correctos
      flash[:error] = "Insufficient classification parameters submitted"
    else
      if params[:signature_id]
        sig_gid, sig_sid = params[:signature_id].split("-")
        options.merge!({:sig_sid => sig_sid, :sig_gid => sig_gid})
      end
      auto_classification = AutoClassification.new(options)
      if !auto_classification.save
        flash[:error] = "An error has ocurred."
      end
    end

    redirect_to auto_classifications_path
  
  end

  def edit_auto
    @auto_classification = AutoClassification.get(params[:id])
    @signature = Signature.last(:sig_sid => @auto_classification.sig_sid, :sig_gid => @auto_classification.sig_gid)
    render :layout => false
  end

  def update_auto

    @auto_classification = AutoClassification.get(params[:id])
    
    if params[:signature_id].present?
      signature = Signature.get(params[:signature_id])
      params[:auto_class][:sig_sid] = signature.sig_sid
      params[:auto_class][:sig_gid] = signature.sig_gid 
    else
      params[:auto_class][:sig_sid] = nil
      params[:auto_class][:sig_gid] = nil
    end

    params[:auto_class].each{|key, value| value.blank? ? params[:auto_class][key] = nil : nil}

    if !@auto_classification.update(params[:auto_class])
      flash[:error] = "An error has ocurred."
    end

    redirect_to auto_classifications_path
  end

  def destroy_auto
    auto_classification = AutoClassification.get(params[:id])
    auto_classification.destroy

    redirect_to auto_classifications_path
  end

  def order_auto
    order = params[:positions].split(";")
    order.each_with_index do |auto_id, position|
      AutoClassification.get(auto_id).update(:position => (position + 1))
    end
  end

end