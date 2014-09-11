module ActsAsTaggable
  module ActMethod #:nodoc:
    def acts_as_taggable(options = {})
      has_many :taggings, :as => :taggable, :after_remove => :delete_tag_if_necessary, :dependent => :destroy
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
      tags = find_tags(tags)
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
    def applied_tags
      joins(:tags).group('tags.id').select("tags.*, COUNT(*) AS count")
    end

    def applied_tag_names
      applied_tags.collect(&:name)
    end

    def tags
      Tag.where(:tag_type => name)
    end

    def tag_names
      tags.collect(&:name)
    end

    def create_tag(tag_name)
      find_tags(tag_name).first || tags.create!(:name => tag_name)
    end

    # Given an unsanitized string or list of tags, Returns a list of tags
    def find_tags(input)
      case input
      when Tag
        [input]
      when String
        tags.where(:name => input.split(acts_as_taggable_options[:delimiter]).collect{|tag_name| tag_name}).to_a
      when Array
        input.flat_map {|tag| find_tags(tag)}.select(&:present?).uniq
      when ActiveRecord::Relation
        input.uniq.to_a
      else
        []
      end
    end
  end

  module InstanceMethods
    def acts_like_taggable?
      true
    end

    def tag_with(*tag_names)
      tag_names.flatten.select(&:present?).each do |tag_name|
        tag = self.class.create_tag(tag_name)
        tags << tag unless tags.to_a.include?(tag)
      end
    end

    def untag_with(*tag_names)
      tag_names.flatten.select(&:present?).each do |tag_name|
        tag = self.class.find_tags(tag_name).first
        taggings.where(:tag_id => tag.id).destroy_all if tag
      end
    end

    def tag_string=(tag_string)
      self.tags = tag_string.to_s.split(acts_as_taggable_options[:delimiter]).collect do |tag_name|
        self.class.create_tag(tag_name)
      end
    end

    def tag_string
      tag_names.join(acts_as_taggable_options[:output_delimiter] + ' ')
    end

    def tag_names
      tags.collect(&:name) # don't use pluck since we want to use the cached association
    end

    private

    def delete_tag_if_necessary(tagging)
      self.class.tags.where(:id => tagging.tag_id).destroy_all if acts_as_taggable_options[:remove_tag_if_empty] && tagging.tag.taggings.count == 0
    end
  end
end

