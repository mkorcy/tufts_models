require 'spec_helper'

describe RecordsHelper do
  it "should have object_type_options" do
    helper.object_type_options.should == {'Audio' => 'TuftsAudio', 'PDF' => 'TuftsPdf'}
  end

  it "should have model_labels" do
    helper.model_label('TuftsAudio').should == 'audio'
    helper.model_label('TuftsPdf').should == 'PDF'
  end
end