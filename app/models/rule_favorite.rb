require 'snorby/model/counter'

class RuleFavorite
  include DataMapper::Resource
  include Snorby::Model::Counter

  belongs_to :user
  belongs_to :rule, :child_key => [ :rule_id ], :parent_key => [ :rule_id ]

  property :id, Serial, :index => true
  property :rule_id, Integer, :index => true
  property :user_id, Integer, :index => true

  after :create do
    self.rule.up(:users_count) if self.rule
    self.user.up(:rule_favorites_count) if self.user
  end
  
  before :destroy! do
    self.rule.down(:users_count) if self.rule
    self.user.down(:rule_favorites_count) if self.user
  end
end
