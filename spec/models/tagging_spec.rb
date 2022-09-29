require 'spec_helper'

describe ActsAsTaggable::Tagging do
  let(:klass) { new_dummy_class { acts_as_taggable } }

  describe '#create!' do
    it "raises an exception if the taggable_type doesn't match the Tag's taggable_type" do
      tag = klass.create_tag('red')
      other_class = new_dummy_class { acts_as_taggable }

      expect{ other_class.create.tags << tag }.to raise_exception(ActiveRecord::RecordInvalid)
    end
  end
end
