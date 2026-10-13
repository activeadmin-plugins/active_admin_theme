# Demo page with a real Trix (ActionText) editor so the theme's Trix chrome can
# be seen and screenshotted. The hidden input carries sample formatted HTML that
# Trix loads on init, exercising the toolbar states and .trix-content styles.
ActiveAdmin.register_page "Rich text" do
  menu priority: 2

  SAMPLE_HTML = <<~HTML
    <h1>Release notes</h1>
    <div>A <strong>themed</strong> Trix editor with <em>italics</em>, a
    <a href="https://example.com">link</a> and inline <code>code</code>.</div>
    <ul><li>First bullet</li><li>Second bullet</li></ul>
    <blockquote>Quoted text follows the theme border.</blockquote>
    <pre>$ bundle exec rake</pre>
  HTML

  content do
    panel "Trix / ActionText" do
      value = ERB::Util.html_escape(SAMPLE_HTML)
      html = %(<input id="trix_demo" type="hidden" value="#{value}">) +
             %(<trix-editor input="trix_demo" class="trix-content"></trix-editor>)
      text_node(html.html_safe)
    end
  end
end
