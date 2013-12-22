module ActsAsTaggable
  module ActMethod #:nodoc:
    def acts_as_taggable(options = {})
      has_many :taggings, :as => :taggable, :after_remove => :delete_tag_if_necessary
      has_many :tags, :through => :taggings

      class_attribute :acts_as_taggable_options
      self.acts_as_taggable_options = options
      self.acts_as_taggable_options.reverse_merge! :delimiter => ',', :downcase => true, :remove_tag_if_empty => true
      self.acts_as_taggable_options.reverse_merge! :output_delimiter => acts_as_taggable_options[:delimiter]

      extend ActsAsTaggable::ClassMethods
      include ActsAsTaggable::InstanceMethods
    end
  end

  module ClassMethods

    def tagged_with_any(*tags)
      p tags = find_tags(tags)
      return all if tags.empty?

      table_alias = "alias_#{tags.hash.abs}"
      scope = all.select "#{table_name}.*"
      scope = scope.joins "JOIN taggings AS #{table_alias} ON #{table_alias}.taggable_id = #{table_name}.id"
      scope = scope.where "#{table_alias}.tag_id" => tags
      scope = scope.group "#{table_name}.#{primary_key}"

      return scope
    end

    def tagged_with_all(*tags)
      tags = find_tags(tags)
      tags.inject(all.uniq) do |scope, tag|
        scope = scope.joins "LEFT OUTER JOIN taggings AS alias_#{tag.id} ON alias_#{tag.id}.taggable_id = #{table_name}.id"
        scope = scope.where "alias_#{tag.id}.tag_id" => tag
      end
    end

    # Make it possible to ask for tags on a scoped Taggable relation. e.g. Users.online.tags
    def tags
      all.joins(:tags).group('tags.id').select("tags.*, COUNT(*) AS count")
    end

    def tag_names
      tags.collect(&:name)
    end

    private

    # Given an unsanitized string or list of tags, Returns a list of tags
    def find_tags(tags)
      case tags
      when String
        Tag.where(:name => tags.split(acts_as_taggable_options[:delimiter]))
      when Array
        tags.flat_map {|tag| find_tags(tag)}.select(&:present?).uniq
      when ActiveRecord::Relation
        tags.uniq
      else
        []
      end
    end
  end

  module InstanceMethods
    def acts_like_taggable?
      true
    end

    def tag_string=(tag_string)
      self.tags = tag_string.to_s.split(acts_as_taggable_options[:delimiter]).collect{|tag_name| Tag.find_or_create_by!(:name => Tag.sanitize_name(tag_name, :downcase => acts_as_taggable_options[:downcase])) }
    end

    def tag_string
      tag_names.join(acts_as_taggable_options[:output_delimiter] + ' ')
    end

    def tag_names
      tags.collect(&:name) # don't use pluck since we want to use the cached association
    end

    private

    def delete_tag_if_necessary
      Tag.where(:id => tag_id).delete_all if acts_as_taggable_options[:remove_tag_if_empty] && tag.taggings.count == 0
    end
  end
end

