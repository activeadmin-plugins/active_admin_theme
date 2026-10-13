Rails.application.routes.draw do
  ActiveAdmin.routes(self)
  root to: redirect("/admin")
end
