module ActsAsTaggable
  module ActMethod #:nodoc:
    def acts_as_taggable(options = {})
      has_many :taggings, :as => :taggable
      has_many :tags, :through => :taggings

      extend ActsAsTaggable::ClassMethods
      include ActsAsTaggable::InstanceMethods
    end    
  end

  module ClassMethods
    # TODO: tagged_with_all
    
    def tagged_with_any(*args)
      args.flatten! # Allow an array of tags to be passed in

      joins(:tags).where(:tags => {:name => args.collect {|tag_name| Tag.sanitize_name(tag_name) } }).uniq
    end

    # Make it possible to ask for tags on a scoped Taggable relation. e.g. Users.online.tags
    def tags
      Tag.joins(:taggings).where(:taggings => {:taggable_type => self, :taggable_id => all}).group('tags.id').select("tags.*, COUNT(*) AS count")
    end
  end

  module InstanceMethods
    TAG_DELIMITER = ','
    
    def acts_like_taggable?
      true
    end

    def tags_list=(tag_string)
      self.tags = tag_string.to_s.split(TAG_DELIMITER).collect{|tag_name| Tag.find_or_create_by!(:name => Tag.sanitize_name(tag_name)) }
    end
    
    def tags_list
      tag_names.join(TAG_DELIMITER + ' ')
    end
    
    def tag_names
      tags.collect(&:name) # don't use pluck since we want to use the cached association
    end
  end
end

