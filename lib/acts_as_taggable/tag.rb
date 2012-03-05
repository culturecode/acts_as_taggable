class Tag < ActiveRecord::Base
  validates_presence_of :name
  
  before_save :sanitize_name
  
  def self.sanitize_name(name)
    name.strip.squeeze(' ').downcase
  end
  
  private
  
  def sanitize_name
    self.name = self.class.sanitize_name(self.name)
  end
end