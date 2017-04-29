require 'spec_helper'

describe ReputationsController do

  def mock_reputation(stubs={})
    (@mock_reputation ||= mock_model(Reputation).as_null_object).tap do |reputation|
      reputation.stub(stubs) unless stubs.empty?
    end
  end

  describe "GET index" do
    it "assigns all reputations as @reputations" do
      Reputation.stub(:all) { [mock_reputation] }
      get :index
      assigns(:reputations).should eq([mock_reputation])
    end
  end

  describe "GET show" do
    it "assigns the requested reputation as @reputation" do
      Reputation.stub(:get).with("37") { mock_reputation }
      get :show, :id => "37"
      assigns(:reputation).should be(mock_reputation)
    end
  end

  describe "GET new" do
    it "assigns a new reputation as @reputation" do
      Reputation.stub(:new) { mock_reputation }
      get :new
      assigns(:reputation).should be(mock_reputation)
    end
  end

  describe "GET edit" do
    it "assigns the requested reputation as @reputation" do
      Reputation.stub(:get).with("37") { mock_reputation }
      get :edit, :id => "37"
      assigns(:reputation).should be(mock_reputation)
    end
  end

  describe "POST create" do

    describe "with valid params" do
      it "assigns a newly created reputation as @reputation" do
        Reputation.stub(:new).with({'these' => 'params'}) { mock_reputation(:save => true) }
        post :create, :reputation => {'these' => 'params'}
        assigns(:reputation).should be(mock_reputation)
      end

      it "redirects to the created reputation" do
        Reputation.stub(:new) { mock_reputation(:save => true) }
        post :create, :reputation => {}
        response.should redirect_to(reputation_url(mock_reputation))
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved reputation as @reputation" do
        Reputation.stub(:new).with({'these' => 'params'}) { mock_reputation(:save => false) }
        post :create, :reputation => {'these' => 'params'}
        assigns(:reputation).should be(mock_reputation)
      end

      it "re-renders the 'new' template" do
        Reputation.stub(:new) { mock_reputation(:save => false) }
        post :create, :reputation => {}
        response.should render_template("new")
      end
    end

  end

  describe "PUT update" do

    describe "with valid params" do
      it "updates the requested reputation" do
        Reputation.should_receive(:get).with("37") { mock_reputation }
        mock_reputation.should_receive(:update).with({'these' => 'params'})
        put :update, :id => "37", :reputation => {'these' => 'params'}
      end

      it "assigns the requested reputation as @reputation" do
        Reputation.stub(:get) { mock_reputation(:update => true) }
        put :update, :id => "1"
        assigns(:reputation).should be(mock_reputation)
      end

      it "redirects to the reputation" do
        Reputation.stub(:get) { mock_reputation(:update => true) }
        put :update, :id => "1"
        response.should redirect_to(reputation_url(mock_reputation))
      end
    end

    describe "with invalid params" do
      it "assigns the reputation as @reputation" do
        Reputation.stub(:get) { mock_reputation(:update => false) }
        put :update, :id => "1"
        assigns(:reputation).should be(mock_reputation)
      end

      it "re-renders the 'edit' template" do
        Reputation.stub(:get) { mock_reputation(:update => false) }
        put :update, :id => "1"
        response.should render_template("edit")
      end
    end

  end

  describe "DELETE destroy" do
    it "destroys the requested reputation" do
      Reputation.should_receive(:get).with("37") { mock_reputation }
      mock_reputation.should_receive(:destroy)
      delete :destroy, :id => "37"
    end

    it "redirects to the reputations list" do
      Reputation.stub(:get) { mock_reputation }
      delete :destroy, :id => "1"
      response.should redirect_to(reputations_url)
    end
  end

end
