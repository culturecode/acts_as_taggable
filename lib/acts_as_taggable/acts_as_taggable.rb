module ActsAsTaggable
  module ActMethod #:nodoc:
    def acts_as_taggable(options = {})
      has_many :taggings, :as => :taggable
      has_many :tags, :through => :taggings, :order => 'name ASC'
      
      # TODO
      # scope :tagged_with_all, lambda {|*args| }
      scope :tagged_with_any, lambda {|*args| joins(:tags).where(:tags => {:name => args.collect{|tag_name| Tag.sanitize_name(tag_name) }} )}

      extend ActsAsTaggable::ClassMethods
      include ActsAsTaggable::InstanceMethods
    end    
  end

  module ClassMethods
  end
  
  module InstanceMethods
    TAG_DELIMITER = ','
    
    def acts_like_taggable?
      true
    end

    def tags_list=(tag_string)
      self.tags = tag_string.split(TAG_DELIMITER).collect{|tag_name| Tag.find_or_create_by_name(Tag.sanitize_name(tag_name)) }
    end
    
    def tags_list
      tags.collect(&:name).join(TAG_DELIMITER + ' ')
    end
  end
end

