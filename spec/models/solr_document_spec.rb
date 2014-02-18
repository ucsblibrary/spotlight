require 'spec_helper'

describe SolrDocument do
  subject { ::SolrDocument.new(id: 'abcd123') }
  its(:to_key) {should == ['abcd123']}
  its(:persisted?) {should be_true}

  it "should have tags on the exhibit" do
    expect(subject.tags_from(Spotlight::Exhibit.default)).to be_empty
  end

  it "should be able to add tags" do
    expect {
      Spotlight::Exhibit.default.tag(subject, with: "paris, normandy", on: :tags)
    }.to change { ActsAsTaggableOn::Tag.count}.by(2)
    subject.tags_from(Spotlight::Exhibit.default).should eq ['paris', 'normandy']
  end

  it "should have find" do
    expect(::SolrDocument.find('dq287tq6352')).to be_kind_of SolrDocument
  end

  describe "#sidebar" do
    it "should return a sidecar for adding exhibit-specific fields" do
      expect(subject.sidecar(Spotlight::Exhibit.default)).to be_kind_of Spotlight::SolrDocumentSidecar
    end
  end

  describe "#update" do
    it "should store sidecar data on the sidecar object" do
      mock_sidecar = double
      subject.stub(sidecar: mock_sidecar)
      mock_sidecar.should_receive(:update).with(data: { 'a' => 1 })
      subject.update Spotlight::Exhibit.default, sidecar: { data: { 'a' => 1 }}
    end
    it "should store tags" do
      subject.update Spotlight::Exhibit.default, exhibit_tag_list: "paris, normandy"
      subject.tags_from(Spotlight::Exhibit.default).should eq ['paris', 'normandy']
    end
  end

  describe "#to_solr" do
    before do
      subject.stub(sidecar: double(to_solr: { id: 'abcd123', a: 1, b: 2, c: 3 }))
    end

    it "should include the doc id" do
      expect(subject.to_solr[:id]).to eq 'abcd123' 
    end

    it "should include exhibit-specific tags" do
      Spotlight::Exhibit.default.tag(subject, with: 'paris', on: :tags)

      expect(subject.to_solr).to include :exhibit_1_tags_sim
      expect(subject.to_solr[:exhibit_1_tags_sim]).to include 'paris'
    end

    it "should include sidecar fields" do
      expect(subject.to_solr).to include(a: 1, b: 2, c:3)
    end
  end
end

