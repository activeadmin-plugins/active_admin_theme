class Order < ActiveRecord::Base
  STATUSES = %w[new paid shipped].freeze

  belongs_to :customer, optional: true
  belongs_to :country, optional: true
  belongs_to :city, optional: true

  def self.ransackable_attributes(_auth = nil)
    %w[reference status customer_id country_id city_id created_at]
  end

  def self.ransackable_associations(_auth = nil)
    %w[customer country city]
  end

  def display_name = reference
end
