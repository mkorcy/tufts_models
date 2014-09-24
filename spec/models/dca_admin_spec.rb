require 'spec_helper'

describe DcaAdmin do

  subject { DcaAdmin.new(nil, 'DCA-ADMIN') }

  it 'has template_name' do
    title = 'Title for a Template'
    subject.template_name = title
    expect(subject.template_name).to eq [title]
  end

  it "should have a published date" do
    time = DateTime.parse('2013-03-22T12:33:00Z')
    subject.published_at = time
    expect(subject.published_at).to eq [time]
  end

  it "should have an edited date" do
    time = DateTime.parse('2013-03-22T12:33:00Z')
    subject.edited_at = time
    expect(subject.edited_at).to eq [time]
  end

  it "should index displays so the tufts-image-library app can search for items" do
    subject.displays = ['dl', 'tdil']
    expect(subject.to_solr['displays_ssim']).to match_array ['dl', 'tdil']
  end

  it "should index the published and edited dates" do
    time = DateTime.parse('2013-03-22T12:33:00Z')
    subject.edited_at = time
    subject.published_at = time
    expect(subject.to_solr).to eq(
      "edited_at_dtsi" => '2013-03-22T12:33:00Z',
      'published_at_dtsi' => '2013-03-22T12:33:00Z')
  end

  it "should have note" do
    subject.note = 'self-deposit'
    expect(subject.note).to eq ['self-deposit']
    subject.note = 'admin-deposit'
    expect(subject.note).to eq ['admin-deposit']
  end

  it "should have createdby" do
    subject.createdby = 'selfdep'
    expect(subject.createdby).to eq ['selfdep']
    subject.createdby = 'admin-deposit'
    expect(subject.createdby).to eq ['admin-deposit']
  end

  it "should have creatordept" do
    subject.creatordept = 'Dept. of Biology'
    expect(subject.creatordept).to eq ['Dept. of Biology']
  end

  it 'has batch_id' do
    subject.batch_id = ['1', '2', '3']
    expect(subject.batch_id).to eq ['1', '2', '3']
  end

  it "should index an embargo date as a date" do
    subject.embargo='2023-06-12'
    expect(subject.to_solr).to eq(
      "embargo_dtsim" =>['2023-06-12T00:00:00Z'])
  end

end
