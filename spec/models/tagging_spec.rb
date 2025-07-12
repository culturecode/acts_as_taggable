require 'spec_helper'

describe ActsAsTaggable::Tagging do
  let(:klass) { new_dummy_class(:type) { acts_as_taggable } }
  let(:subklass) { eval("class #{klass}Subclass < #{klass}; end; #{klass}Subclass") }

  describe '#create!' do
    it "raises an exception if the taggable_type doesn't match the Tag's taggable_type" do
      tag = klass.create_tag('red')
      other_class = new_dummy_class { acts_as_taggable }

      expect{ other_class.create.tags << tag }.to raise_exception(ActiveRecord::RecordInvalid)
    end

    it "does not raise an exception if the taggable_type is an STI subclass of an allowed taggable" do
      tag = subklass.create_tag('red')

      expect{ subklass.create.tags << tag }.not_to raise_exception
    end
  end
end
