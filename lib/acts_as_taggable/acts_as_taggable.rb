module ActsAsTaggable
  module ActMethod #:nodoc:
    def acts_as_taggable(options = {})
      has_many :taggings, :as => :taggable
      has_many :tags, :through => :taggings
      
      # TODO
      # scope :tagged_with_all, lambda {|*args| }
      scope :tagged_with_any, lambda {|*args| joins(:tags).where(:tags => {:name => args.collect{|tag_name| Tag.sanitize_name(tag_name) }} )}

      # Delegate the relation methods to the relation
      class << self
        delegate :tags, :to => :scoped
      end

      extend ActsAsTaggable::ClassMethods
      include ActsAsTaggable::InstanceMethods
      ActiveRecord::Relation.send :include, ActsAsTaggable::ActiveRelationMethods
    end    
  end

  module ClassMethods
  end

  module ActiveRelationMethods
    def tags
      scoping { Tag.select("tags.id, tags.name, COUNT(*) AS count").joins(:taggings).where(:taggings => {:taggable_type => @klass.name}).group('tags.id') }
    end
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
      tag_names.join(TAG_DELIMITER + ' ')
    end
    
    def tag_names
      tags.collect(&:name) # don't use pluck since we want to use the cached association
    end
  end
end

