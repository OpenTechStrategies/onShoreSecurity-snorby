require 'spec_helper'

describe "reputations/index.html.erb" do
  before(:each) do
    assign(:reputations, [
      stub_model(reputation,
        :[type_id => "",
        :value => "",
        :action_id => "",
        :sensor_id => ""
      ),
      stub_model(reputation,
        :[type_id => "",
        :value => "",
        :action_id => "",
        :sensor_id => ""
      )
    ])
  end

  it "renders a list of reputations" do
    render
    # Run the generator again with the --webrat-matchers flag if you want to use webrat matchers
    assert_select "tr>td", :text => "".to_s, :count => 2
    # Run the generator again with the --webrat-matchers flag if you want to use webrat matchers
    assert_select "tr>td", :text => "".to_s, :count => 2
    # Run the generator again with the --webrat-matchers flag if you want to use webrat matchers
    assert_select "tr>td", :text => "".to_s, :count => 2
    # Run the generator again with the --webrat-matchers flag if you want to use webrat matchers
    assert_select "tr>td", :text => "".to_s, :count => 2
  end
end
