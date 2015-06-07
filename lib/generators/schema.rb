class ActsAsTaggableTable < ActiveRecord::Migration
  def change
    create_table :acts_as_taggable_tags do |t|
      t.string :name
      t.string :taggable_type
      t.string :tag_type
    end

    create_table :acts_as_taggable_taggings do |t|
      t.belongs_to :tag
      t.belongs_to :taggable, :polymorphic => true
    end

    add_index :acts_as_taggable_tags, [:name, :taggable_type, :tag_type], :name => "ensure_uniqueness_of_acts_as_taggable_tags", :unique => true
    add_index :acts_as_taggable_taggings, [:taggable_type, :taggable_id], :name => "index_acts_as_taggable_tagging_associations"
    add_index :acts_as_taggable_taggings, :tag_id
  end
end
