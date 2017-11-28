require 'nokogiri'
require 'uri'

activate :syntax

activate :blog do |blog|
  blog.prefix = "blog"
  blog.permalink = "{year}/{title}.html"
  blog.sources = "{year}/{title}.html"
  blog.layout = "layouts/post"
  # blog.tag_template = "tag.html"
  # blog.taglink = "{tag}/index.html"
  # blog.calendar_template = "calendar.html"
  blog.default_extension = ".md"

  # Enable pagination
  blog.paginate = true
  blog.per_page = 6
  blog.page_link = "page/{num}"

  blog.generate_day_pages = false
  blog.generate_month_pages = false
  blog.generate_year_pages = false

  blog.custom_collections = {
    category: {
      link: '/{category}.html',
      template: '/category.html'
    }
  }
end

helpers do
  def category_longname(name)
    {
      'code' => 'Design &amp; Development',
      'misc' => 'Miscellany',
      'food' => 'Food &amp; Fermentation'
    }[name]
  end

  def categories
    blog.articles.map { |p| p.data.category }.compact.uniq.sort
  end

  def previous_article_in_category(article)
    blog.articles.select {|a| a.data.category == article.data.category}.find {|a| a.date < article.date }
  end
  def next_article_in_category(article)
    blog.articles.reverse.select {|a| a.data.category == article.data.category}.find {|a| a.date > article.date }
  end

  def insert_toc(page_content)
    html_doc = Nokogiri::HTML::DocumentFragment.parse(page_content)

    headers = "<div class='col gap-1 contents'><h2>Contents</h2><ol class='col'>"
    html_doc.css('h2').each do |header|
      id = URI.encode_www_form_component(header.text.to_s.downcase.gsub(" ", "-"))
      header.set_attribute('id', id)
      headers += "<li><a href='##{id}'>#{header.children}</a></li>"
    end
    headers += "</ol></div>"

    html_doc.css('h2').first.add_previous_sibling(headers) if html_doc.css('h2').length > 0

    html_doc
  end
end

page "/feed.xml", layout: false

helpers do
  def reading_time(article)
    hours, mins, secs = article.body.reading_time(:format=>:raw)
    mins += 1 if secs >= 30
    mins += hours * 60
    mins = 1 if mins == 0
    "#{mins} min read"
  end
end

set :markdown_engine, :redcarpet
set :markdown, :fenced_code_blocks => true, :smartypants => true, :footnotes => true
set :css_dir, 'stylesheets'
set :js_dir, 'javascripts'
set :images_d, 'images'

activate :directory_indexes
page "/404.html", :directory_index => false
page "/notes/*", :layout => "note"

# Build-specific configuration
configure :build do
  activate :minify_css
  activate :minify_javascript
  activate :asset_hash
end

