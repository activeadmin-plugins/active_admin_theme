# DB-backed resource: index with filters and batch actions, show, and a form.
ActiveAdmin.register Customer do
  permit_params :name, :email, :country, :status, :balance, :notes

  filter :name
  filter :email
  filter :country
  filter :status, as: :select, collection: Customer::STATUSES
  filter :balance
  filter :created_at

  index do
    selectable_column
    id_column
    column :name
    column :email
    column :country
    column :status
    column :balance
    column :created_at
    actions
  end

  sidebar "Help", only: :show do
    para "Sidebar content shows inside a panel."
  end

  show do
    columns "1:2" do
      column do
        attributes_table do
          row :name
          row :email
          row :country
          row :status
          row :balance
          row :created_at
        end
      end
      column do
        tabs do
          tab "Notes" do
            panel("Notes") { para resource.notes }
          end
          tab "Raw" do
            pre resource.attributes.inspect
          end
        end
      end
    end
  end

  form do |f|
    f.inputs do
      f.input :name
      f.input :email
      f.input :country, as: :string
      f.input :status, as: :select, collection: Customer::STATUSES
      f.input :balance
      f.input :notes
    end
    f.actions
  end
end
