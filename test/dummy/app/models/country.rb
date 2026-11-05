class Country < ActiveRecord::Base
  has_many :cities

  def self.ransackable_attributes(_auth = nil)
    %w[name]
  end

  def self.ransackable_associations(_auth = nil)
    []
  end

  def display_name = name
end
