# Demo of the opt-in components: status_tag colors, truncate_text,
# secret_reveal, with_tooltip and pre_wrap.
ActiveAdmin.register_page "Components" do
  menu parent: "Demo pages", priority: 6

  page_action :secret, method: :get do
    render json: {value: "s3cr3t"}
  end

  page_action :forbidden, method: :get do
    head :forbidden
  end

  content do
    # A host defines the color of a custom status in its own CSS.
    text_node "<style>:root { --aat-status-shipped: #7c3aed; }</style>".html_safe
    # secret_reveal is opt-in: the page loads its script.
    text_node '<script type="module">import "active_admin_theme/secret_reveal"</script>'.html_safe

    panel "Status tags" do
      div id: "status-tags" do
        %w[ok warning error info empty yes shipped unstyled].each { |status| status_tag status }
        status_tag false
        status_tag "Late", color: "#b91c1c", id: "status-late"
      end
    end

    panel "Truncate text" do
      long = "A long sentence that does not fit in the space it is given, so it is cut."
      div(id: "truncate-default") { truncate_text long }
      div(id: "truncate-narrow") { truncate_text long, max_width: "8rem" }
      div(id: "truncate-length") { truncate_text long, length: 20 }
    end

    panel "Secret reveal" do
      div(id: "secret") { secret_reveal url: "/admin/components/secret" }
    end

    panel "Tooltips" do
      div id: "tooltips" do
        span(id: "tooltip-title") { text_node with_tooltip("Hover for a title", "Plain title tooltip") }
        text_node " "
        span(id: "tooltip-html") { text_node with_tooltip("Hover for HTML", "<strong>Rich</strong> tooltip<script>alert(1)</script>", html: true) }
      end
    end

    panel "Pre wrap" do
      div id: "pre-wrap" do
        text_node pre_wrap("first line\n" + "x" * 400)
      end
    end
  end
end
