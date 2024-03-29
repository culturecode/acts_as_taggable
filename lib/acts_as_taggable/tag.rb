module ActsAsTaggable
  class Tag < ActiveRecord::Base
    self.table_name = "acts_as_taggable_tags"

    has_many :taggings, :dependent => :destroy
    default_scope lambda { order(:name) }

    validates_presence_of :name, :taggable_type
    before_save :sanitize_name

    def to_s
      self.name
    end

    def taggable_class
      self.taggable_type.constantize
    end

    # Returns a cache key that is unique based on the last time the tags were updated or applied
    def taggings_cache_key
      [name, taggings.maximum(:id), taggings.count]
    end

    private

    def sanitize_name
      self.name = taggable_class.sanitize_tag_name(name)
    end
  end
end
