require 'nokogiri'
require 'httparty'
require 'byebug'

def crawler
  uri = 'https://magento-test.finology.com.my/breathe-easy-tank.html'
  html_page = HTTParty.get(uri)
  parsed_page = Nokogiri::HTML(html_page)


  linked_pages = []
  product_links =[]
  products =[]

  # Associated pages of main page
  puts "========Associated page Links========"
  puts "====================================="
  parsed_page.css("li a").each do |link|
    url = link.attributes["href"]&.value
    next if url.nil? || url[/#|account|create|login|sale|contact|about-us|privacy-policy|customer-service|search/]
    linked_pages << url
  end
  puts linked_pages
  puts "====================================="

  # Collect data of main page product & save in array
  product = get_product(parsed_page)
  products << product

  # Find links of all products of main page & save in array
  main_page_products = get_product_links(parsed_page)
  product_links = product_links | main_page_products

  # Visit associated pages
  # Find links of all products of each associated page & save in array
  linked_pages.each do |linked_uri|
    linked_page = HTTParty.get(linked_uri)
    linked_parsed = Nokogiri::HTML(linked_page)
    product_urls = get_product_links(linked_parsed)

    # Add two arrays and remove duplicate products
    product_links = product_links | product_urls

    # Check of page has pagination
    # If there is pagination applied on page
    # Process each page of pagination
    # Get products links
    pagination_links = get_pagination_products(linked_parsed) unless linked_parsed.css("div.pages").nil?
    unless pagination_links.nil?
      pagination_links.each do |page|
        pagination_page = HTTParty.get(page)
        pagination_parsed = Nokogiri::HTML(pagination_page)
        pagination_product_urls = get_product_links(pagination_parsed)

        # Add two arrays and remove duplicate products
        product_links = product_links | pagination_product_urls
      end
    end
  end

  # Visit each product link and collect data
  product_links.each do |link|
    product_page = HTTParty.get(link)
    product_parsed = Nokogiri::HTML(product_page)
    product = get_product(product_parsed)
    products << product
  end


  # Show all products on console
  puts "=============***Products***============="
  puts "========================================"
  puts products
  puts "========================================"
  puts "***Total Products: #{ products.count }***"
  puts "========================================"
end

def get_product_links(parsed_page)
  product_links = []

  parsed_page.css("a.product-item-link").each do |product|
    product_uri = product.attributes["href"]&.value
    next if product_uri.nil?
    product_links << product_uri
  end
  return product_links
end

def get_pagination_products(parsed_page)
  links = []
  parsed_page.css("div.pages ul li.item a").each do |link|
    url = link.attributes["href"]&.value
    next if url.nil?
    links << url
  end
  return links
end

def get_product(product_parsed)
  extra_info = []

  product_parsed.css("table.data.table.additional-attributes").search("tr").each do |row|
    obj = "#{row.at('th').text()}: #{row.at('td').text()}"
    extra_info << obj
  end

  product = {
    Name: product_parsed.css("span.base").text(),
    Price: product_parsed.css("span.price")[0].text(),
    Description: product_parsed.css("div.product.attribute.description").search("p").text(),
    ExtraInformation: extra_info.join('|')
  }
  return product
end


crawler

