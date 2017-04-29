require "spec_helper"

describe ReputationsController do
  describe "routing" do

    it "recognizes and generates #index" do
      { :get => "/reputations" }.should route_to(:controller => "reputations", :action => "index")
    end

    it "recognizes and generates #new" do
      { :get => "/reputations/new" }.should route_to(:controller => "reputations", :action => "new")
    end

    it "recognizes and generates #show" do
      { :get => "/reputations/1" }.should route_to(:controller => "reputations", :action => "show", :id => "1")
    end

    it "recognizes and generates #edit" do
      { :get => "/reputations/1/edit" }.should route_to(:controller => "reputations", :action => "edit", :id => "1")
    end

    it "recognizes and generates #create" do
      { :post => "/reputations" }.should route_to(:controller => "reputations", :action => "create")
    end

    it "recognizes and generates #update" do
      { :put => "/reputations/1" }.should route_to(:controller => "reputations", :action => "update", :id => "1")
    end

    it "recognizes and generates #destroy" do
      { :delete => "/reputations/1" }.should route_to(:controller => "reputations", :action => "destroy", :id => "1")
    end

  end
end
