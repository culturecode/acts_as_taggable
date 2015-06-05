require 'spec_helper'

describe Tag do
  let(:klass) { new_dummy_class { acts_as_taggable } }

  describe '#create!' do
    it 'raises an exception if no taggable_type is specified' do
      expect{ Tag.create!(:name => 'bob') }.to raise_exception(ActiveRecord::RecordInvalid)
    end
  end
end
