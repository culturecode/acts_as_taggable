require 'spec_helper'

describe 'acts_as_taggable' do
  let(:klass) { new_dummy_class { acts_as_taggable :types => [:material] } }
  let(:red) { klass.create_tag('red') }
  let(:metal) { klass.create_material_tag('metal') }
  let(:wood) { klass.create_material_tag('wood') }
  let(:record) { klass.create! }

  before do
    ActsAsTaggable::Tag.destroy_all # Because we're using sqlite3 and it doesn't support transactional specs (afaik)
    red
    metal
  end

  describe '::create_tag_type_tags' do
    it 'creates tags of the given tag type' do
      expect(metal.tag_type).to eq('material')
    end
  end

  describe '::find_tag_type_tags' do
    it 'returns only tags matching the tag type when given tags' do
      expect(klass.find_material_tags(red, metal)).to contain_exactly(metal)
    end

    it 'returns only tags matching the tag type when given a string of mixed tags' do
      expect(klass.find_material_tags("red, metal")).to contain_exactly(metal)
    end
  end

  describe '::tagged_with_any_tag_type' do
    it 'returns the records tagged with any of the tags' do
      record.tags << [red, metal]
      expect(klass.tagged_with_any_material(wood,metal)).to contain_exactly(record)
    end

    it "doesn't return records if they are not tagged with any of the tags of the tag type" do
      record.tags << [red, metal]
      expect(klass.tagged_with_any_material(red, wood)).to be_empty
    end
  end

  describe '::tagged_with_all_pluralized_tag_type' do
    it 'returns the records tagged with all of the tags of the tag type' do
      record.tags << [red, metal, wood]
      expect(klass.tagged_with_all_materials(metal, wood, red)).to contain_exactly(record)
    end

    it "doesn't return records if given a single tag of a different tag type" do
      record.tags << [red, metal]
      expect(klass.tagged_with_all_materials(red)).to be_empty
    end
  end

  describe '::applied_tag_type_tags' do
    it 'returns only tags of the given type that have been applied to records' do
      record.tags << [red, metal]
      expect(klass.applied_material_tags).to contain_exactly(metal)
    end

    it 'returns only tags of the given type from this class' do
      other_klass = new_dummy_class { acts_as_taggable :types => :material }
      other_klass.create.tags << other_klass.create_material_tag('glass')

      record.tags << metal
      expect(klass.applied_tags).to contain_exactly(metal)
    end
  end

  describe '#tag_type_taggings' do
    it "returns only taggings where the tag's tag type matches" do
      record.tags << [red, metal]
      expect(record.material_taggings.collect(&:tag)).to contain_exactly(metal)
    end
  end

  describe '#tag_type_tags' do
    it "returns only tags where the tag's tag type matches" do
      record.tags << [red, metal]
      expect(record.material_tags).to contain_exactly(metal)
    end
  end
end
