module ActsAsTaggable
  module ActMethod #:nodoc:
    def acts_as_taggable(options = {})
      class_attribute :acts_as_taggable_options
      self.acts_as_taggable_options = options
      self.acts_as_taggable_options.reverse_merge! :delimiter => ',', :downcase => true, :remove_tag_if_empty => true
      self.acts_as_taggable_options.reverse_merge! :output_delimiter => acts_as_taggable_options[:delimiter]
      self.acts_as_taggable_options[:types] = Array(self.acts_as_taggable_options[:types])

      has_many :taggings, -> { order("#{Tagging.table_name}.id") }, :as => :taggable, :after_remove => :delete_tag_if_necessary, :dependent => :destroy, :class_name => 'ActsAsTaggable::Tagging'
      has_many :tags, :through => :taggings, :class_name => 'ActsAsTaggable::Tag', :after_add => :reset_scoped_associations

      extend ClassMethods
      include InstanceMethods

      self.acts_as_taggable_options[:types].each do |tag_type|
        has_many :"#{tag_type}_taggings", -> { joins(:tag).order("#{Tagging.table_name}.id").where(Tag.table_name => {:tag_type => tag_type}) }, :as => :taggable, :after_remove => :delete_tag_if_necessary, :class_name => 'ActsAsTaggable::Tagging'
        has_many :"#{tag_type}_tags", -> { where(:tag_type => tag_type) }, :through => :taggings, :source => :tag, :class_name => 'ActsAsTaggable::Tag', :after_add => :reset_associations

        metaclass = class << self; self; end
        HelperMethods.scope_class_methods(metaclass, tag_type)
        HelperMethods.scope_instance_methods(self, tag_type)
      end
    end
  end

  module ClassMethods

    def tagged_with_any(*tags)
      tags = find_tags(tags)
      return none if tags.empty?

      table_alias = "alias_#{tags.hash.abs}"
      scope = all.uniq.select "#{table_name}.*"
      scope = scope.joins "JOIN #{Tagging.table_name} AS #{table_alias} ON #{table_alias}.taggable_id = #{table_name}.id"
      scope = scope.where "#{table_alias}.tag_id" => tags

      return scope
    end

    def tagged_with_all(*tags)
      tags = find_tags(tags)
      return none if tags.empty?

      tags.inject(all.uniq) do |scope, tag|
        scope = scope.joins "LEFT OUTER JOIN #{Tagging.table_name} AS alias_#{tag.id} ON alias_#{tag.id}.taggable_id = #{table_name}.id"
        scope = scope.where "alias_#{tag.id}.tag_id" => tag
      end
    end

    # Make it possible to ask for tags on a scoped Taggable relation. e.g. Users.online.applied_tags
    def applied_tags
      Tag.select("#{Tag.table_name}.*, COUNT(*) AS count").joins(:taggings).where(:taggable_type => self.name, Tagging.table_name => {:taggable_id => all}).group("#{Tag.table_name}.id")
    end

    def applied_tag_names
      applied_tags.pluck(:name)
    end

    def tags
      Tag.where(:taggable_type => name)
    end

    def tag_names
      tags.pluck(:name)
    end

    def create_tag(tag_name)
      find_tags(tag_name).first || tags.create!(:name => tag_name)
    end

    # Given an unsanitized string or list of tags, Returns a list of tags
    def find_tags(*input)
      input = input.flatten
      input = input.first if input.one?
      case input
      when Tag
        HelperMethods.filter_tags_by_current_tag_scope([input])
      when String
        tags.where(:name => input.split(acts_as_taggable_options[:delimiter]).collect {|tag_name| tag_name.strip}).to_a
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
      self.tag_names = tag_names.flatten
    end

    def untag_with(*tag_names)
      self.tag_names = self.tag_names - self.class.find_tags(tag_names).collect(&:name)
    end

    def tag_string
      tag_names.join(acts_as_taggable_options[:output_delimiter] + ' ')
    end

    def tag_string=(tag_string)
      self.tag_names = tag_string.to_s.split(acts_as_taggable_options[:delimiter])
    end

    def tag_names
      tags.collect(&:name) # don't use pluck since we want to use the cached association
    end

    def tag_names=(names)
      self.tags = names.select(&:present?).collect do |tag_name|
        self.class.create_tag(tag_name)
      end
    end

    private

    def delete_tag_if_necessary(tagging)
      self.class.tags.where(:id => tagging.tag_id).destroy_all if acts_as_taggable_options[:remove_tag_if_empty] && tagging.tag.taggings.count == 0
    end

    def reset_scoped_associations(record)
      return unless record.tag_type
      send("#{record.tag_type}_taggings").reset
      send("#{record.tag_type}_tags").reset
    end

    def reset_associations(record)
      send(:taggings).reset
      send(:tags).reset
    end
  end

  module HelperMethods
    def self.scope_class_methods(context, tag_type)
      scope_tag_method(context, tag_type, :create_tag, :"create_#{tag_type}_tag")
      scope_tag_method(context, tag_type, :find_tags, :"find_#{tag_type}_tags")
      scope_tag_method(context, tag_type, :tagged_with_any, :"tagged_with_any_#{tag_type}")
      scope_tag_method(context, tag_type, :tagged_with_all, :"tagged_with_all_#{tag_type.to_s.pluralize}")
      scope_tag_method(context, tag_type, :tags, :"#{tag_type}_tags")
      scope_tag_method(context, tag_type, :tag_names, :"#{tag_type}_tag_names")
      scope_tag_method(context, tag_type, :applied_tags, :"applied_#{tag_type}_tags")
      scope_tag_method(context, tag_type, :applied_tag_names, :"applied_#{tag_type}_tag_names")
    end

    def self.scope_instance_methods(context, tag_type)
      scope_tag_method(context, tag_type, :tag_names, :"#{tag_type}_tag_names")
      scope_tag_method(context, tag_type, :tag_string, :"#{tag_type}_tag_string")
      scope_tag_method(context, tag_type, :tag_string=, :"#{tag_type}_tag_string=")
      scope_tag_method(context, tag_type, :tag_with, :"tag_with_#{tag_type}")
      scope_tag_method(context, tag_type, :untag_with, :"untag_with_#{tag_type}")
    end

    def self.scope_tag_method(context, tag_type, method_name, scoped_method_name)
      context.send :define_method, scoped_method_name do |*args|
        Tag.where(:tag_type => tag_type).scoping do
          send(method_name, *args)
        end
      end
    end

    # Filters an array of tags by the current tag scope, e.g. :tag_type => 'material'
    def self.filter_tags_by_current_tag_scope(tags)
      return tags unless Tag.current_scope
      current_tag_scope = Tag.current_scope.where_values_hash
      tags.select do |tag|
        current_tag_scope.all? do |attribute, value|
          tag[attribute].to_s == value.to_s
        end
      end
    end
  end
end
