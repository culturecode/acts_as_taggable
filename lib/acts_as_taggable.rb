require 'acts_as_taggable/acts_as_taggable'
require 'acts_as_taggable/tag'
require 'acts_as_taggable/tagging'

module ActsAsTaggable
end

ActiveRecord::Base.extend ActsAsTaggable::ActMethod
