class Tagging < ActiveRecord::Base
  belongs_to :tag
  belongs_to :taggable, :polymorphic => true

  validate :taggable_type_matches


  private

  def taggable_type_matches
    errors.add(:taggable_type, "can't be tagged with a tag from another class") if tag.taggable_type != taggable_type
  end
end
