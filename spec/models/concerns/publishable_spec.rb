require 'spec_helper'

class TestObject < ActiveFedora::Base
  include Publishable
end

describe Publishable do

  describe '.build_draft_version' do
    subject { TestObject.build_draft_version(attrs) }

    context 'with no PID given' do
      let(:attrs) { Hash.new }

      it 'sets the draft namespace so that the saved object will have a draft PID' do
        expect(subject.inner_object.namespace).to eq 'draft'
        expect(subject.pid).to be_nil
        subject.save!
        expect(subject.pid).to match /^draft:.*$/
      end
    end

    context 'with a namespace given' do
      let(:attrs) {{ namespace: 'tufts' }}

      it 'overrides the namespace with the draft namespace' do
        expect(subject.inner_object.namespace).to eq 'draft'
      end
    end

    context 'with a non-draft PID given' do
      let(:pid) { 'tufts:123' }
      let(:draft_pid) { 'draft:123' }
      let(:attrs) {{ pid: pid }}

      it 'converts the PID to a draft PID' do
        expect(subject.pid).to eq draft_pid
      end
    end
  end

  describe '#publish!' do
    let(:user) { FactoryGirl.create(:user) }

    let(:obj) do
      TuftsImage.create(title: 'My title', displays: ['dl']).tap do |image|
        image.datastreams['Thumbnail.png'].dsLocation = "http://bucket01.lib.tufts.edu/data01/tufts/central/dca/UA136/thumb_png/UA136.002.DO.02673.thumbnail.png"
        image.save
      end
    end

    after do
      obj.destroy if obj
    end

    context "when a published version does not exist" do

      let(:published_pid) { PidUtils.to_published(obj.pid) }

      it "results in a published copy of the draft" do
        expect {
          obj.publish!
        }.to change { TuftsImage.exists?(published_pid) }.from(false).to(true)

        published_obj = obj.find_published
        expect(published_obj).to be_published
        expect(published_obj.title).to eq 'My title'
        expect(published_obj.displays).to eq ['dl']
        expect(published_obj.datastreams['Thumbnail.png']).not_to be_new
      end
    end

    context "when a published version already exists" do
      let(:published_pid) { PidUtils.to_published(obj.pid) }
      before { obj.publish! }

      it "replaces the existing published copy" do
        obj.update_attributes title: 'Edited title'
        obj.publish!
        published_obj = obj.find_published
        expect(published_obj.title).to eq 'Edited title'
      end

    end


    it 'adds an entry to the audit log' do
      expect(obj).to receive(:audit).with(instance_of(User), 'Pushed to production').once

      obj.publish!(user.id)
    end

    it 'results in the image being published' do
      expect(obj.published_at).to eq(nil)

      obj.publish!
      obj.reload
      expect(obj.published?).to be_truthy
    end

    it 'only updates the published_at time when actually published' do
      expect(obj.published_at).to eq nil

      obj.publish!(user.id)

      expect(obj.published_at).to_not be_nil
    end
  end

  describe '#unpublish!' do
    let(:obj) { TuftsImage.build_draft_version(title: 'My title', displays: ['dl']) }
    let(:user) { FactoryGirl.create(:user) }
    before do
      obj.save
      obj.publish!
    end

    it "deletes the published copy, retains the draft, and logs the action" do
      expect(obj).to receive(:audit).with(instance_of(User), 'Unpublished').once
      obj.unpublish!(user.id)
      expect { obj.find_published }.to raise_error ActiveFedora::ObjectNotFoundError
      expect(obj.find_draft).not_to be_published
    end
  end

  describe '#find_draft' do
    before { ActiveFedora::Base.delete_all }

    let!(:record) { TestObject.create!(pid: 'tufts:123') }

    context 'given a record with a draft version' do
      let!(:draft_record) {
        obj = TestObject.build_draft_version(record.attributes.except('id').merge(pid: record.pid))
        obj.save!
        obj
      }

      it 'finds the draft version of that record' do
        expect(record.find_draft).to eq draft_record
      end
    end

    context 'given a record without a draft version' do
      it 'raises an exception' do
        expect{ record.find_draft }.to raise_error ActiveFedora::ObjectNotFoundError
      end
    end
  end


  describe '#draft?' do
    subject { TestObject.new(pid: pid, namespace: namespace) }

    context 'with a non-draft PID' do
      let(:pid) { 'tufts:123' }
      let(:namespace) { nil }

      it 'reports non-draft status' do
        expect(subject.draft?).to be_falsey
      end
    end

    context 'a PID with the draft namespace' do
      let(:pid) { 'draft:123' }
      let(:namespace) { nil }

      it 'reports draft status' do
        expect(subject.draft?).to be_truthy
      end
    end

    context 'with no PID, but draft namespace' do
      let(:pid) { nil }
      let(:namespace) { PidUtils.draft_namespace }

      it 'reports draft status' do
        expect(subject.draft?).to be_truthy
      end
    end

    context 'with no PID, but non-draft namespace' do
      let(:pid) { nil }
      let(:namespace) { PidUtils.published_namespace }

      it 'reports non-draft status' do
        expect(subject.draft?).to be_falsey
      end
    end

    context 'with no PID and no namespace' do
      let(:pid) { nil }
      let(:namespace) { nil }

      it 'reports non-draft status' do
        expect(subject.draft?).to be_falsey
      end
    end
  end

  describe "#purge!" do
    subject { TuftsImage.build_draft_version(title: 'My title', displays: ['dl']) }

    let(:user) { FactoryGirl.create(:user) }
    let(:draft_pid) { PidUtils.to_draft(subject.pid) }
    let(:published_pid) { PidUtils.to_published(subject.pid) }

    context "when only the published version exists" do
      # not a very likely scenario
      before do
        subject.save!
        subject.publish!
        subject.destroy
      end

      it "hard-deletes the published version" do
        expect(TuftsImage.exists?(published_pid)).to be_truthy

        subject.purge!

        expect(TuftsImage.exists?(published_pid)).to be_falsey
      end

      it "creates an audit log" do
        expect(subject).to receive(:audit).with(instance_of(User), "Purged published version").once
        expect(subject).to receive(:audit).with(instance_of(User), "Purged draft version").never

        subject.purge!(user)
      end
    end

    context "when the draft version exists" do
      before do
        subject.save!
      end

      it "hard-deletes the draft version" do
        expect(TuftsImage.exists?(draft_pid)).to be_truthy
        subject.purge!
        expect(TuftsImage.exists?(draft_pid)).to be_falsey
      end

      it "creates an audit log" do
        expect(subject).to receive(:audit).with(instance_of(User), "Purged published version").never
        expect(subject).to receive(:audit).with(instance_of(User), "Purged draft version").once

        subject.purge!(user)
      end
    end

    context "when both versions exist" do
      before do
        subject.save!
        subject.publish!
      end

      it "hard-deletes both versions" do
        expect(TuftsImage.exists?(draft_pid)).to be_truthy
        expect(TuftsImage.exists?(published_pid)).to be_truthy

        subject.purge!

        expect(TuftsImage.exists?(draft_pid)).to be_falsey
        expect(TuftsImage.exists?(published_pid)).to be_falsey
      end

      it "creates an audit log" do
        expect(subject).to receive(:audit).with(instance_of(User), "Purged published version").once
        expect(subject).to receive(:audit).with(instance_of(User), "Purged draft version").once

        subject.purge!(user)
      end
    end

  end # purge!

end
