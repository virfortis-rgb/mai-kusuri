module ApplicationHelper
    def render_markdown(text)
    Commonmarker.to_html(text, options: { extension: { footnotes: true }, render: { github_pre_tag: true, unsafe: true } }).html_safe
  end
end
