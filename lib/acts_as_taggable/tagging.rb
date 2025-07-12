module ActsAsTaggable
  class Tagging < ActiveRecord::Base
    self.table_name = "acts_as_taggable_taggings"

    belongs_to :tag
    belongs_to :taggable, :polymorphic => true

    validate :taggable_type_matches


    private

    def taggable_type_matches
      errors.add(:taggable_type, "can't be tagged with a tag from another class") unless tag.taggable_type.constantize <= taggable_type.constantize
    end
  end
end
