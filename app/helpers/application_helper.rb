module ApplicationHelper
  def render_markdown(text)
    Kramdown::Document.new(text).to_html
  end
end
