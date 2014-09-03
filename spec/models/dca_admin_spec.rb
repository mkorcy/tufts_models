require 'spec_helper'

describe DcaAdmin do

  subject { DcaAdmin.new(nil, 'DCA-ADMIN') }

  it 'has template_name' do
    title = 'Title for a Template'
    subject.template_name = title
    subject.template_name.should == [title]
  end

  it "should have a published date" do
    time = DateTime.parse('2013-03-22T12:33:00Z')
    subject.published_at = time
    subject.published_at.should == [time]
  end

  it "should have an edited date" do
    time = DateTime.parse('2013-03-22T12:33:00Z')
    subject.edited_at = time
    subject.edited_at.should == [time]
  end

  it "should index the published and edited dates" do
    time = DateTime.parse('2013-03-22T12:33:00Z')
    subject.edited_at = time
    subject.published_at = time
    subject.to_solr.should == {
       "edited_at_dtsi" =>'2013-03-22T12:33:00Z', 'published_at_dtsi' =>'2013-03-22T12:33:00Z'}
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


  context "parsing xml" do
    context "that has nodes with the default namespace" do
      let(:source) { "<admin #{namespaces}> <steward>Hey</steward> </admin>" }

      before do
        subject.content = source
      end

      context "and without a prefix 'local' defined" do
        let(:namespaces) { 'xmlns="http://nils.lib.tufts.edu/dcaadmin/" xmlns:ac="http://purl.org/dc/dcmitype/"' }
        describe "read" do
          it "should have steward" do
            expect(subject.steward).to eq ['Hey']
          end
        end

        describe "write" do
          context "a new node" do
            before do
              subject.note = ['foo']
            end

            it "should add the prefixed node" do
              expect(subject.to_xml).to eq "<admin xmlns=\"http://nils.lib.tufts.edu/dcaadmin/\" xmlns:ac=\"http://purl.org/dc/dcmitype/\" xmlns:local=\"http://nils.lib.tufts.edu/dcaadmin/\"> <steward>Hey</steward> <local:note>foo</local:note></admin>"
            end
          end

          context "an existing node" do
            before do
              subject.steward = ['foo', 'bar']
            end

            it "should add the prefixed node" do
              expect(subject.to_xml).to eq "<admin xmlns=\"http://nils.lib.tufts.edu/dcaadmin/\" xmlns:ac=\"http://purl.org/dc/dcmitype/\" xmlns:local=\"http://nils.lib.tufts.edu/dcaadmin/\"> <steward>foo</steward> <local:steward>bar</local:steward></admin>"
              expect(subject.steward).to eq ['foo', 'bar']
            end
          end
        end
      end

      context "source with both prefix" do
        let(:namespaces) { 'xmlns="http://nils.lib.tufts.edu/dcaadmin/" xmlns:local="http://nils.lib.tufts.edu/dcaadmin/" xmlns:ac="http://purl.org/dc/dcmitype/"' }
        it "should have steward" do
          expect(subject.steward).to eq ['Hey']
        end
      end
    end

    context "with nodes that are prefixed" do
      let(:source) { "<admin #{namespaces}> <local:steward>Hey</local:steward> </admin>" }

      before do
        subject.content = source
      end

      context "and the local prefix is defined and no default namespace" do
        let(:namespaces) { 'xmlns:local="http://nils.lib.tufts.edu/dcaadmin/" xmlns:ac="http://purl.org/dc/dcmitype/"' }
        it "should have steward" do
          expect(subject.steward).to eq ['Hey']
        end
      end

      context "and a local prefix and the default namespace are defined" do
        let(:namespaces) { 'xmlns="http://nils.lib.tufts.edu/dcaadmin/" xmlns:local="http://nils.lib.tufts.edu/dcaadmin/" xmlns:ac="http://purl.org/dc/dcmitype/"' }
        describe "read" do
          it "should have steward" do
            expect(subject.steward).to eq ['Hey']
          end
        end

        describe "write" do
          context "a new node" do
            before do
              subject.note = ['foo']
            end

            it "should add the prefixed node" do
              expect(subject.to_xml).to eq "<admin xmlns=\"http://nils.lib.tufts.edu/dcaadmin/\" xmlns:local=\"http://nils.lib.tufts.edu/dcaadmin/\" xmlns:ac=\"http://purl.org/dc/dcmitype/\"> <local:steward>Hey</local:steward> <local:note>foo</local:note></admin>"
            end
          end

          context "an existing node" do
            before do
              subject.steward = ['foo', 'bar']
            end

            it "should add the prefixed node" do
              expect(subject.to_xml).to eq "<admin xmlns=\"http://nils.lib.tufts.edu/dcaadmin/\" xmlns:local=\"http://nils.lib.tufts.edu/dcaadmin/\" xmlns:ac=\"http://purl.org/dc/dcmitype/\"> <local:steward>foo</local:steward> <local:steward>bar</local:steward></admin>"
            end
          end
        end
      end
    end
  end

end
