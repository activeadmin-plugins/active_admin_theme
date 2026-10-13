require_relative "application"

# In-memory SQLite: a connection exists if anything asks, but there is no schema
# to maintain (AA comments are disabled and there are no resources).
ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")

Dummy::Application.initialize!
