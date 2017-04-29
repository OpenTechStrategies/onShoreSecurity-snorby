require 'spec_helper'

describe "reputations/edit.html.erb" do
  before(:each) do
    @reputation = assign(:reputation, stub_model(reputation,
      :new_record? => false,
      :[type_id => "",
      :value => "",
      :action_id => "",
      :sensor_id => ""
    ))
  end

  it "renders the edit reputation form" do
    render

    # Run the generator again with the --webrat-matchers flag if you want to use webrat matchers
    assert_select "form", :action => reputation_path(@reputation), :method => "post" do
      assert_select "input#reputation_[type_id", :name => "reputation[[type_id]"
      assert_select "input#reputation_value", :name => "reputation[value]"
      assert_select "input#reputation_action_id", :name => "reputation[action_id]"
      assert_select "input#reputation_sensor_id", :name => "reputation[sensor_id]"
    end
  end
end
