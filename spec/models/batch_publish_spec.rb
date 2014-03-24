require 'spec_helper'

describe BatchPublish do
  subject { FactoryGirl.build(:batch_publish) }
  after { subject.delete if subject.persisted? }

  it 'requires a list of pids' do
    subject.pids = nil
    expect(subject.valid?).to be_false
    expect(subject.errors[:pids]).to eq ["can't be blank"]
  end

  it 'serializes the pids on save' do
    subject.save!
  end

  it "knows if it's ready to run" do
    invalid_batch = BatchPublish.new
    expect(invalid_batch.ready?).to be_false
    expect(subject.ready?).to be_true
  end

  it "only runs when it's ready, returns false if not ready" do
    invalid_batch = BatchPublish.new
    expect(invalid_batch.ready?).to be_false
    expect(invalid_batch.run).to be_false
  end

  it 'queues a publish job for each pid' do
    obj1 = FactoryGirl.create(:tufts_pdf)
    obj2 = FactoryGirl.create(:tufts_audio)

    batch = FactoryGirl.build(:batch_publish, pids: [obj1.id, obj2.id])

    job1 = double
    job2 = double

    expect(Job::Publish).to receive(:new).with(batch.creator.id, obj1.id) { job1 }
    expect(Job::Publish).to receive(:new).with(batch.creator.id, obj2.id) { job2 }

    expect(Tufts.queue).to receive(:push).with(job1)
    expect(Tufts.queue).to receive(:push).with(job2)

    return_value = batch.run
    expect(return_value).to be_true

    obj1.delete
    obj2.delete
  end

end