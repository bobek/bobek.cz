xml.instruct!
xml.feed "xmlns" => "http://www.w3.org/2005/Atom" do
  site_url = "https://bobek.cz"
  xml.title "bobek.cz"
  xml.subtitle "a blog by Antonín Král"
  xml.id site_url
  xml.link "href" => URI.join(site_url, blog('blog').options.prefix.to_s)
  xml.link "href" => URI.join(site_url, current_page.path), "rel" => "self"
  xml.updated(blog('blog').articles.first.date.to_time.iso8601) unless blog('blog').articles.empty?
  xml.author { xml.name "Antonín Král" }

  blog('long-reads').articles[0..2].each do |article|
    xml.entry do
      xml.title article.title
      xml.subtitle article.data.subtitle if article.data.subtitle
      xml.link "rel" => "alternate", "href" => URI.join(site_url, article.url)
      xml.id URI.join(site_url, article.url)
      xml.published article.date.to_time.iso8601
      xml.updated File.mtime(article.source_file).iso8601
      xml.author { xml.name "Antonín Král" }
      # xml.summary article.summary, "type" => "html"
      xml.content article.body, "type" => "html"
    end
  end

  blog('blog').articles[0..5].each do |article|
    xml.entry do
      xml.title article.title
      xml.subtitle article.data.subtitle if article.data.subtitle
      xml.link "rel" => "alternate", "href" => URI.join(site_url, article.url)
      xml.id URI.join(site_url, article.url)
      xml.published article.date.to_time.iso8601
      xml.updated File.mtime(article.source_file).iso8601
      xml.author { xml.name "Antonín Král" }
      # xml.summary article.summary, "type" => "html"
      xml.content article.body, "type" => "html"
    end
  end
end
