# Demo of the confirm_dialog component. Every dialog submits to the echo action
# below, which prints the verb and the submitted fields instead of changing data.
ActiveAdmin.register_page "Confirm dialog" do
  menu parent: "Demo pages", priority: 6

  page_action :echo, method: [:post, :delete] do
    submitted = params.to_unsafe_h.except("authenticity_token", "_method", "controller", "action")
    render plain: "#{request.request_method} #{submitted.to_json}"
  end

  content do
    panel "Plain confirm" do
      confirm_dialog "Archive customer", id: "plain-confirm", title: "Archive customer?",
                                         message: "The customer is hidden from the lists.",
                                         url: "/admin/confirm_dialog/echo", confirm_text: "Archive"
    end

    panel "Confirm with fields" do
      confirm_dialog "Flag customer", id: "fields-confirm", title: "Flag customer", url: "/admin/confirm_dialog/echo",
                                      confirm_text: "Send",
                                      fields: [
                                        {name: :reason, label: "Reason", as: :text, required: true},
                                        {name: :title, label: "Short title", as: :string},
                                        {name: :priority, label: "Priority", as: :select, collection: [["Low", "low"], ["High", "high"]]},
                                        {name: :notify, label: "Notify customer", as: :boolean}
                                      ]
    end

    panel "Submit with a method" do
      confirm_dialog "Delete customer", id: "delete-confirm", title: "Delete customer?",
                                        message: "This cannot be undone.",
                                        url: "/admin/confirm_dialog/echo", method: :delete, confirm_text: "Delete"
    end
  end
end
