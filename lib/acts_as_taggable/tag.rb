class Tag < ActiveRecord::Base
  has_many :taggings
  default_scope :order => 'name ASC'
  
  validates_presence_of :name
  before_save :sanitize_name
  
  def self.sanitize_name(name)
    name.to_s.strip.squeeze(' ').downcase
  end
  
  def to_s
    self.name
  end

  private
  
  def sanitize_name
    self.name = self.class.sanitize_name(self.name)
  end
end