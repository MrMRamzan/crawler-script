require 'nokogiri'
require 'httparty'
require 'byebug'

class CrawlerService

  # Find all associated pages
  def self.get_linked_pages(parsed_page)
    page_links = []

    parsed_page.css("li a").each do |link|
      url = link.attributes["href"]&.value
      # Get links only those pages having products
      next if url.nil? || url[/#|account|create|login|sale|contact|about-us|privacy-policy|customer-service|search/]
      page_links << url
    end
    return page_links
  end

  # Visit link and return parsed html page
  def self.get_parsed_page(link)
    html_page = HTTParty.get(link)
    parsed_page = Nokogiri::HTML(html_page)
  end

  # Process parsed page and return product links
  def self.get_product_links(parsed_page)
    product_links = []

    parsed_page.css("a.product-item-link").each do |product|
      product_uri = product.attributes["href"]&.value
      next if product_uri.nil?
      product_links << product_uri
    end
    return product_links
  end

  # Get all product pagination links 
  def self.get_pagination_links(parsed_page)
    links = []

    parsed_page.css("div.pages ul li.item a").each do |link|
      url = link.attributes["href"]&.value
      next if url.nil?
      links << url
    end
    return links
  end

  # Collect product data from product show page
  def self.get_product(product_parsed)
    extra_info = []

    product_parsed.css("table.data.table.additional-attributes").search("tr").each do |row|
      obj = "#{row.at('th').text()}: #{row.at('td').text()}"
      extra_info << obj
    end

    product = {
      Name: product_parsed.css("span.base").text(),
      Price: product_parsed.css("span.price")[0].text().strip[1..-1],
      Description: product_parsed.css("div.product.attribute.description").search("p").text(),
      ExtraInformation: extra_info.join('|')
    }
    return product
  end
end
