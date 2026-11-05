class ApplicationController < ActionController::Base
  DemoUser = Struct.new(:name)

  private

  # Stands in for Devise's current user so the header's user area renders.
  def current_admin_user
    DemoUser.new("Demo Admin")
  end
end
