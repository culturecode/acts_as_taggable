require 'spec_helper'

describe 'acts_as_taggable' do
  let(:klass) { new_dummy_class { acts_as_taggable } }

  before do
    ActsAsTaggable::Tag.destroy_all # Because we're using sqlite3 and it doesn't support transactional specs (afaik)
  end

  describe '::acts_as_taggable' do
    it "adds the tags association to the model" do
      expect(klass.reflect_on_association(:tags)).to be_present
    end
  end

  describe '::create_tag' do
    it 'accepts a string' do
      tag = klass.create_tag('red')

      expect(tag.name).to eq('red')
      expect(tag).to be_an_instance_of(ActsAsTaggable::Tag)
    end

    it 'creates lowercase tags by default' do
      expect {
        lower_tag = klass.create_tag('red')
        upper_tag = klass.create_tag('RED')

        expect(lower_tag.name).to eq('red')
        expect(upper_tag.name).to eq('red')
        expect(lower_tag).to eq(upper_tag)
      }.to change { ActsAsTaggable::Tag.count }.by(1)
    end

    it 'creates case-senstive tags' do
      insensitive_klass = new_dummy_class { acts_as_taggable :downcase => false }
      expect {
        lower_tag = insensitive_klass.create_tag('red')
        upper_tag = insensitive_klass.create_tag('RED')

        expect(lower_tag.name).to eq('red')
        expect(upper_tag.name).to eq('RED')
        expect(lower_tag).not_to eq(upper_tag)
      }.to change { ActsAsTaggable::Tag.count }.by(2)
    end
  end

  describe '::find_tags' do
    let(:red) { klass.create_tag('red') }
    let(:green) { klass.create_tag('green') }

    it 'returns an array of matching tags when given a single tag' do
      expect(klass.find_tags(red)).to contain_exactly(red)
    end

    it 'returns an array of matching tags when given a string' do
      expect(klass.find_tags(red.name)).to contain_exactly(red)
    end

    it 'accepts an array of tags' do
      expect(klass.find_tags([red, green])).to contain_exactly(red, green)
    end

    it 'accepts an array of tag names' do
      expect(klass.find_tags([red.name, green.name])).to contain_exactly(red, green)
    end

    it 'accepts a comma delimited string of tags' do
      expect(klass.find_tags("#{red.name}, #{green.name}")).to contain_exactly(red, green)
    end

    it 'accepts an ActiveRecord::Relation of tags' do
      expect(klass.find_tags(ActsAsTaggable::Tag.where(:name => red.name))).to contain_exactly(red)
    end

    it 'returns an empty array if a nil is passed' do
      expect(klass.find_tags(nil)).to eq([])
    end
  end

  describe '::tagged_with_any' do
    let(:record) { klass.create! }
    let(:red) { klass.create_tag('red') }
    let(:green) { klass.create_tag('green') }

    it 'returns the records tagged with any of the tags' do
      record.tags << red
      expect(klass.tagged_with_any(red, green)).to contain_exactly(record)
    end

    it "doesn't return records if they are not tagged with any of the tags" do
      record.tags << red
      expect(klass.tagged_with_any(green)).to be_empty
    end

    it 'returns only one copy of a record even if multiple tags match' do
      record.tags = [red, green]
      expect(klass.tagged_with_any(red, green)).to contain_exactly(record)
    end
  end

  describe '::tagged_with_all' do
    let(:record) { klass.create! }
    let(:red) { klass.create_tag('red') }
    let(:green) { klass.create_tag('green') }

    it 'returns the records tagged with all of the tags' do
      record.tags << [red, green]
      expect(klass.tagged_with_all(red, green)).to contain_exactly(record)
    end

    it "doesn't return records if they are not tagged with all of the tags" do
      record.tags << red
      expect(klass.tagged_with_all([red, green])).to be_empty
    end
  end

  describe '::applied_tags' do
    let(:record) { klass.create! }
    let(:red) { klass.create_tag('red') }

    it 'returns only tags that have been applied to records' do
      record.tags << red
      expect(klass.applied_tags).to contain_exactly(red)
    end

    it 'returns only tags from this class' do
      other_klass = new_dummy_class { acts_as_taggable }
      other_klass.create.tags << other_klass.create_tag('blue')

      record.tags << red
      expect(klass.applied_tags).to contain_exactly(red)
    end
  end

  describe '::tags' do
    let(:red) { klass.create_tag('red') }

    it 'returns tags that have been created' do
      expect(klass.tags).to contain_exactly(red)
    end

    it 'returns only tags from this class' do
      other_klass = new_dummy_class { acts_as_taggable }
      other_klass.create_tag('blue')

      expect(klass.tags).to contain_exactly(red)
    end

    it "returns tags from this class' subclasses" do
      subclass = eval("class #{klass}Subclass < #{klass}; end; #{klass}Subclass")
      blue = subclass.create_tag('blue')

      expect(klass.tags).to contain_exactly(blue)
    end
  end

  describe '#tag_names=' do
    let(:record) { klass.create! }
    let(:red) { klass.create_tag('red') }

    it 'accepts an array of strings and sets the tags tag match' do
      record.tag_names = ['red', 'green']
      expect(record.tags.collect(&:name)).to contain_exactly('red', 'green')
    end

    it 'creates with an array of strings and sets the tags tag match' do
      record = klass.create!(:tag_names => ['red', 'green'])
      expect(record.tags.collect(&:name)).to contain_exactly('red', 'green')
    end

    it 'updates with different tags' do
      record.update!(:tag_names => ['blue', 'green'])
      expect(record.tags.collect(&:name)).to contain_exactly('blue', 'green')
    end

    it 'updates with no tags' do
      record.update!(:tag_names => [])
      expect(record.tags.collect(&:name)).to be_empty
    end

    it 'ignores empty strings' do
      record.tag_names = ['', 'green']
      expect(record.tags.collect(&:name)).to contain_exactly('green')
    end

    it "doesn't add duplicate tags" do
      record.tags << red
      record.tag_names = ["red", "red"]
      expect(record.tags.count).to eq(1)
    end
  end

  describe '#tag_with' do
    let(:record) { klass.create! }
    let(:red) { klass.create_tag('red') }

    it 'accepts multiple mixed arguments and sets the tags tag match' do
      record.tag_with(red, 'green')
      expect(record.tags.collect(&:name)).to contain_exactly('red', 'green')
    end
  end

  describe '#tag_with' do
    let(:record) { klass.create! }
    let(:red) { klass.create_tag('red') }

    it 'accepts multiple mixed arguments and unsets the given tags' do
      record.tag_with(red, 'green', 'blue')
      record.untag_with(red, 'green')

      expect(record.tags.collect(&:name)).to contain_exactly('blue')
    end
  end
end
