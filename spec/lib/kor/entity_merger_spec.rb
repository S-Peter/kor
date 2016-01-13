require 'rails_helper'

describe Kor::EntityMerger do
  include DataHelper
  
  it "should merge entities while preserving the dataset" do
    test_data
    
    mona_lisa = Entity.find_by_name('Mona Lisa')
    mona_lisa.dataset = {'gnd' => '12345', 'google_maps' => 'Am Dornbusch 13, 60315 Frankfurt'}
    
    merged = described_class.new.run(:old_ids => Entity.all.map{|e| e.id},
      :attributes => {
        :name => mona_lisa.name,
        :dataset => {
          'gnd' => '12345'
        }
      }
    )
    
    expect(Entity.count).to eql(1)
    expect(merged.dataset['gnd']).to eql('12345')
  end

  it "should preserve synonyms as an array" do
    mona_lisa = FactoryGirl.create :mona_lisa, :synonyms => ["La Gioconda"]
    other_mona_lisa = FactoryGirl.create :mona_lisa, :name => "Mona Liza", :synonyms => ["La Gioconda"]

    merged = described_class.new.run(:old_ids => Entity.all.map{|e| e.id},
      :attributes => {
        :name => mona_lisa.name,
        :synonyms => "La Gioconda"
      }
    )
    
    expect(Entity.count).to eql(1)
    expect(merged.synonyms).to eq(["La Gioconda"])
  end
  
end
