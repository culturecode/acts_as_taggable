class Tag < ActiveRecord::Base
  has_many :taggings, :dependent => :destroy
  default_scope lambda { order(:name) }

  validates_presence_of :name
  before_save :sanitize_name

  def to_s
    self.name
  end

  def taggable_class
    self.tag_type.constantize
  end

  private

  def sanitize_name
    name = self.name.to_s.squish
    name.downcase! if taggable_class.acts_as_taggable_options[:downcase]
    self.name = name
  end
end
