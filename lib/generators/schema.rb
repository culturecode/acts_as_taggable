class ActsAsTaggableTable < ActiveRecord::Migration
  def change
    create_table :tags do |t|
      t.string :name
      t.string :taggable_type
    end

    create_table :taggings do |t|
      t.belongs_to :tag
      t.belongs_to :taggable, :polymorphic => true
    end

    add_index :tags, [:name, :taggable_type], :unique => true
    add_index :taggings, [:taggable_type, :taggable_id]
    add_index :taggings, :tag_id
  end
end
