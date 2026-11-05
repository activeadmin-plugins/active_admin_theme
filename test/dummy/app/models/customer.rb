class Customer < ActiveRecord::Base
  STATUSES = %w[active pending suspended closed].freeze

  def self.ransackable_attributes(_auth = nil)
    %w[name email country status balance created_at]
  end

  def self.ransackable_associations(_auth = nil)
    []
  end

  def display_name = name
end
