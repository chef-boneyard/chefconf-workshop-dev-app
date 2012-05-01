require 'spec_helper'

describe "Group Model" do
  let(:group) { Group.new }
  it 'can be created' do
    group.should_not be_nil
  end
end
