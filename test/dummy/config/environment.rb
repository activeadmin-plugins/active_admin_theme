require_relative "application"

# SQLite file rebuilt at every boot, so there is nothing to migrate. A file, not
# ":memory:": each Puma thread would get its own empty in-memory database.
require "fileutils"
db_file = File.expand_path("../tmp/dummy.sqlite3", __dir__)
FileUtils.mkdir_p(File.dirname(db_file))
FileUtils.rm_f(db_file)

Dummy::Application.initialize!

ActiveRecord::Schema.verbose = false
ActiveRecord::Schema.define do
  create_table :customers do |t|
    t.string :name, :email, :country, :status
    t.decimal :balance, precision: 12, scale: 2, default: 0
    t.text :notes
    t.timestamps
  end
  create_table :countries do |t|
    t.string :name
  end
  create_table :cities do |t|
    t.string :name
    t.references :country
  end
  create_table :orders do |t|
    t.string :reference, :status
    t.references :customer, :country, :city
    t.timestamps
  end
end

countries = %w[UK US NL DE FR UA PL]
30.times do |i|
  Customer.create!(
    name: "Customer #{i + 1}",
    email: "customer#{i + 1}@example.com",
    country: countries[i % countries.size],
    status: Customer::STATUSES[i % Customer::STATUSES.size],
    balance: (i * 137.5) % 5000,
    notes: "Note for customer #{i + 1}. " * 3
  )
end

# 70 countries and 3 cities each: enough rows for the searchable select to page.
# The last country has markup in its name to check that labels are escaped.
country_records = Array.new(70) { |i| Country.create!(name: format("Country %02d", i + 1)) }
country_records << Country.create!(name: %(<i>Italic</i> & "Quoted"))
country_records.each do |country|
  3.times { |i| City.create!(name: "#{country.name} City #{i + 1}", country: country) }
end

customers = Customer.order(:id).to_a
60.times do |i|
  country = country_records[i % 70]
  Order.create!(
    reference: format("ORD-%03d", i + 1),
    status: Order::STATUSES[i % Order::STATUSES.size],
    customer: customers[i % customers.size],
    country: country,
    city: country.cities.first
  )
end
