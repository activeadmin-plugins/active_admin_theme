class City < ActiveRecord::Base
  belongs_to :country

  def self.ransackable_attributes(_auth = nil)
    %w[name country_id]
  end

  def self.ransackable_associations(_auth = nil)
    []
  end

  def display_name = name
end
