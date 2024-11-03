require 'nokogiri'
require 'uri'
require 'pathname'

activate :syntax

activate :blog do |blog|
  blog.name = 'blog'
  blog.permalink = "{title}.html"
  blog.sources = "{year}/{title}.html"
  blog.layout = "layouts/post"
  # blog.tag_template = "tag.html"
  # blog.taglink = "{tag}/index.html"
  # blog.calendar_template = "calendar.html"
  blog.default_extension = ".md"

  # Enable pagination
  blog.paginate = true
  blog.per_page = 12
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

activate :blog do |blog|
  blog.name = "long-reads"
  blog.prefix = "long-reads"
  blog.permalink = "{title}.html"
  blog.sources = "{year}/{title}.html"
  blog.layout = "layouts/post"
  # blog.tag_template = "tag.html"
  # blog.taglink = "{tag}/index.html"
  # blog.calendar_template = "calendar.html"
  blog.default_extension = ".md"

  # Enable pagination
  blog.paginate = true
  blog.per_page = 12
  blog.page_link = "page/{num}"

  blog.generate_day_pages = false
  blog.generate_month_pages = false
  blog.generate_year_pages = false
end

activate :blog do |blog|
  blog.name = "til"
  blog.prefix = "til"
  blog.permalink = "{title}.html"
  blog.sources = "{year}/{title}.html"
  blog.layout = "layouts/post"
  # blog.tag_template = "tag.html"
  # blog.taglink = "{tag}/index.html"
  # blog.calendar_template = "calendar.html"
  blog.default_extension = ".md"

  # Enable pagination
  blog.paginate = true
  blog.per_page = 12
  blog.page_link = "page/{num}"

  blog.generate_day_pages = false
  blog.generate_month_pages = false
  blog.generate_year_pages = false
end

activate :livereload

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

  def canonical_url(page)
    dst_path = page.destination_path.gsub(/index\.html$/, '')
    "https://www.bobek.cz/#{dst_path}"
  end

  def propose_changes_url(src)
    project_root = Pathname.new(File.dirname(__FILE__))
    source_path = Pathname.new(src)

    "https://github.com/bobek/bobek.cz/blob/master/#{source_path.relative_path_from(project_root).to_s}"
  end

  def twitter_url(article)
    url = URI.join("https://bobek.cz", article.url)
    "https://twitter.com/intent/tweet?text=#{article.title} @kralant" \
      "&amp;url=#{url}"
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

class Shortcodes
	cattr_accessor :middleman_app

	def self.sidenote(args)
    %|<span class="sidenote-number"><small class="sidenote">#{args[:snippet_body]}</small></span>|
	end

	def self.parse(snippet)
		handle = /(?<=\[\[)\w+(?=\W)/.match(snippet)[0].to_sym
		args = {}

    args[:snippet_body] = snippet.slice((2 + handle.size + 1)..-3)

		# Create hash of the the provided arguments
		snippet.slice((2 + handle.size)..-3).scan(/\w+="[^"]+"/).each do |x|
			property, value = x.split(/\=/)
			property = property.to_sym
			value = value.slice(1..-2)

			# When multiple properties are used, store each of the values
			# as an array, instead of overwriting each.
			if not args.has_key? property
				args[property] = value
			elsif args[property].is_a? Array
				args[property].push value
			else
				args[property] = [args[property], value]
			end
		end

		# Check if a method exists for the provided handle
		if Shortcodes.methods.include? handle
			Shortcodes.send(handle, args)
		else
			return snippet
		end
	end
end
Shortcodes.middleman_app = self

class Middleman::Renderers::MiddlemanRedcarpetHTML < ::Redcarpet::Render::HTML
	def preprocess(doc)
		doc.gsub(/\[\[\w+.*?\]\]/) { |m| Shortcodes::parse(m) }
	end

	def postprocess(doc)
		# Postprocess with the SmartPants plugin. If not desired
		# the entire postprocess method can be removed.
		doc = Redcarpet::Render::SmartyPants.render(doc)
	end
end

#set :markdown_engine, :kramdown
set :markdown_engine, :redcarpet
# set :markdown, :fenced_code_blocks => true, :smartypants => true, :footnotes => true, link_attributes: { rel: 'nofollow', target: '_blank' }, tables: true,
set :markdown, :fenced_code_blocks => true, :smartypants => false, :footnotes => false, link_attributes: { rel: 'nofollow', target: '_blank' }, tables: true,
      syntax_highlighter: 'rouge', input: 'GFM', with_toc_data: true

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
  activate :asset_hash, ignore: [%r{^files}]
end

