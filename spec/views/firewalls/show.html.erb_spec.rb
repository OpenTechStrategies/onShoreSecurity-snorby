require 'spec_helper'

describe "reputations/show.html.erb" do
  before(:each) do
    @reputation = assign(:reputation, stub_model(reputation,
      :[type_id => "",
      :value => "",
      :action_id => "",
      :sensor_id => ""
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat-matchers flag if you want to use webrat matchers
    rendered.should match(//)
    # Run the generator again with the --webrat-matchers flag if you want to use webrat matchers
    rendered.should match(//)
    # Run the generator again with the --webrat-matchers flag if you want to use webrat matchers
    rendered.should match(//)
    # Run the generator again with the --webrat-matchers flag if you want to use webrat matchers
    rendered.should match(//)
  end
end
