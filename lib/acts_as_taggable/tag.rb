class Tag < ActiveRecord::Base
  has_many :taggings, :dependent => :destroy
  default_scope lambda { order(:name) }

  validates_presence_of :name
  before_save :sanitize_name

  def self.sanitize_name(name, options = {})
    name = name.to_s.squish
    name = name.downcase if options[:downcase]
    return name
  end

  def to_s
    self.name
  end

  private

  def sanitize_name
    self.name = self.class.sanitize_name(self.name)
  end
end
