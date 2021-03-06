require 'rails_helper'

describe Api::OaiPmh::RelationshipsController, :type => :controller do

  include XmlHelper

  render_views

  before :each do
    default = FactoryGirl.create :default
    priv = FactoryGirl.create :private
    admins = FactoryGirl.create :admins
    FactoryGirl.create :admin, :groups => [admins]
    guests = FactoryGirl.create :guests
    FactoryGirl.create :guest, :groups => [guests]
    Grant.create :credential => guests, :collection => default, :policy => 'view'

    Grant.create :credential => admins, :collection => default, :policy => 'view'
    Grant.create :credential => admins, :collection => priv, :policy => 'view'

    mona_lisa = FactoryGirl.create :mona_lisa
    leonardo = FactoryGirl.create :leonardo, :collection_id => priv.id

    FactoryGirl.create :has_created
    Relationship.relate_and_save mona_lisa, "has created", leonardo
  end

  it "should respond to 'Identify'" do
    get :identify, :format => :xml
    expect(response).to be_success
    expect{Hash.from_xml response.body}.not_to raise_error

    post :identify, :format => :xml
    expect(response).to be_success
    expect{Hash.from_xml response.body}.not_to raise_error
  end

  it "should respond to 'ListMetadataFormats'" do
    get :list_metadata_formats, :format => :xml
    expect(response).to be_success
    expect{Hash.from_xml response.body}.not_to raise_error

    post :list_metadata_formats, :format => :xml
    expect(response).to be_success
    expect{Hash.from_xml response.body}.not_to raise_error
  end

  it "should respond to 'ListIdentifiers'" do
    admin = User.admin

    get :list_identifiers, format: :xml, api_key: admin.api_key
    expect(response).to be_success
    expect{Hash.from_xml response.body}.not_to raise_error

    post :list_identifiers, format: :xml, api_key: admin.api_key
    expect(response).to be_success
    expect{Hash.from_xml response.body}.not_to raise_error
  end

  it "should respond to 'ListRecords'" do
    admin = User.admin

    get :list_records, format: :xml, api_key: admin.api_key, metadataPrefix: 'kor'
    expect(response).to be_success
    expect{Hash.from_xml response.body}.not_to raise_error

    post :list_records, format: :xml, api_key: admin.api_key, metadataPrefix: 'kor'
    expect(response).to be_success
    expect{Hash.from_xml response.body}.not_to raise_error
  end


  it "should respond to 'GetRecord'" do
    admin = User.admin
    relationship = Relationship.last

    get(:get_record,
      format: :xml,
      identifier: relationship.uuid, 
      api_key: admin.api_key,
      metadataPrefix: 'kor'
    )
    expect(response).to be_success
    expect{Hash.from_xml response.body}.not_to raise_error

    post(:get_record,
      format: :xml,
      identifier: relationship.uuid, 
      api_key: admin.api_key,
      metadataPrefix: 'kor'
    )
    expect(response).to be_success
    expect{Hash.from_xml response.body}.not_to raise_error
  end

  it "should only include data the user is authorized for" do
    admin = User.admin

    get :list_records, format: :xml, metadataPrefix: 'kor'
    verify_oaipmh_error 'noRecordsMatch'

    get(:list_records,
      format: :xml,
      api_key: admin.api_key,
      metadataPrefix: 'kor'
    )

    items = parse_xml(response.body).xpath("//kor:relationship")

    expect(items.count).to eq(1)
  end

  it "should respond with 403 if the user is not authorized" do
    relationship = Relationship.last

    get(:get_record,
      format: :xml,
      identifier: relationship.uuid,
      metadataPrefix: 'kor'
    )

    expect(response.status).to be(403)
  end

  it "should return XML that validates against the OAI-PMH schema" do
    relationship = Relationship.last
    admin = User.admin

    # yes this sucks, check out 
    # https://mail.gnome.org/archives/xml/2009-November/msg00022.html
    # for a reason why it has to be done like this
    xsd = Nokogiri::XML::Schema(File.read "#{Rails.root}/tmp/oai_pmh_validator.xsd")
    get(:get_record,
      format: :xml,
      identifier: relationship.uuid,
      api_key: admin.api_key,
      metadataPrefix: 'kor'
    )
    doc = parse_xml(response.body)

    expect(xsd.validate(doc)).to be_empty
  end

  it "should disseminate oai_dc and kor metadata formats on GetRecord requests" do
    relationship = Relationship.last
    admin = User.admin

    get(:get_record, 
      :format => :xml, 
      :identifier => relationship.uuid, 
      :api_key => admin.api_key, 
      :metadataPrefix => "oai_dc"
    )
    doc = parse_xml(response.body)
    expect(doc.xpath("//xmlns:metadata/oai_dc:dc").count).to eq(1)

    get(:get_record, 
      :format => :xml, 
      :identifier => relationship.uuid, 
      :api_key => admin.api_key, 
      :metadataPrefix => "kor"
    )
    doc = parse_xml(response.body)
    expect(doc.xpath("//xmlns:metadata/kor:relationship").count).to eq(1)
  end

  it "should disseminate oai_dc and kor metadata formats on ListRecords requests" do
    admin = User.admin

    get(:list_records, 
      :format => :xml, 
      :api_key => admin.api_key, 
      :metadataPrefix => "oai_dc"
    )
    doc = parse_xml(response.body)
    expect(doc.xpath("//xmlns:metadata/oai_dc:dc").count).to eq(1)

    get(:list_records, 
      :format => :xml, 
      :api_key => admin.api_key, 
      :metadataPrefix => "kor"
    )
    doc = parse_xml(response.body)
    expect(doc.xpath("//xmlns:metadata/kor:relationship").count).to eq(1)
  end

  it "should return 'idDoesNotExist' if the identifier given does not exist" do
    get(:get_record, 
      format: :xml, 
      identifier: '1234', 
      metadataPrefix: 'kor'
    )

    verify_oaipmh_error 'idDoesNotExist'
  end

  it "should return 'noRecordsMatch' if the criteria do not yield any records" do
    Relationship.destroy_all
    admin = User.admin

    get :list_identifiers, format: :xml
    verify_oaipmh_error 'noRecordsMatch'

    get(:list_records,
      format: :xml, 
      api_key: admin.api_key,
      metadataPrefix: 'kor'
    )
    verify_oaipmh_error 'noRecordsMatch'
  end

end