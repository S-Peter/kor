require 'rails_helper'

RSpec.describe CollectionsController, :type => :controller do
  include DataHelper

  before :each do
    fake_authentication :persist => true
  end
  
  it "should update" do
    collection = FactoryGirl.create :collection, :name => 'Test Collection'
    
    patch :update, :id => collection.id, :collection => {
      'grants_by_policy' => {
        'view' => [@admins.id.to_s]
    }}
    
    expect(response).to redirect_to(collections_path)
    expect(Collection.last.grants.with_policy(:view).map{|g| g.credential}).to eq([@admins])
  end
  
end
