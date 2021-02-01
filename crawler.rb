require_relative 'crawler_service'
require_relative 'product'
require 'byebug'

def crawler
  # main url for starting crawling
  uri = 'https://magento-test.finology.com.my/breathe-easy-tank.html'
  parsed_page = CrawlerService.get_parsed_page(uri)

  product_links =[]
  products =[]

  # Associated pages of main page
  linked_pages = CrawlerService.get_linked_pages(parsed_page)

  # Collect data of main page product & save in array
  product = CrawlerService.get_product(parsed_page)
  products << product

  # Find links of all products of main page & save in array
  main_page_products = CrawlerService.get_product_links(parsed_page)
  product_links = product_links | main_page_products

  # Visit associated pages
  # Find links of all products of each associated page & save in array
  linked_pages.each do |linked_uri|
    linked_parsed = CrawlerService.get_parsed_page(linked_uri)
    product_urls = CrawlerService.get_product_links(linked_parsed)
    # Add two arrays and remove duplicate products
    product_links = product_links | product_urls
    # Check either page has pagination
    # If there is pagination applied on page
    # Process each page of pagination
    # Get products links
    pagination_links = CrawlerService.get_pagination_links(linked_parsed) unless linked_parsed.css("div.pages").nil?
    unless pagination_links.nil?
      pagination_links.each do |page|
        pagination_parsed = CrawlerService.get_parsed_page(page)
        pagination_product_urls = CrawlerService.get_product_links(pagination_parsed)
        # Add two arrays and remove duplicate product links
        product_links = product_links | pagination_product_urls
      end
    end
  end

  # Visit each product link and collect data
  product_links.each do |link|
    product_parsed = CrawlerService.get_parsed_page(link)
    product = CrawlerService.get_product(product_parsed)
    products << product
  end
  
  # Save products in sqlite db
  products.each do |product|
    Product.create(product)
  end

  # Show all products on console
  puts "=============***Products***============="
  puts "========================================"
  puts products
  puts "========================================"
  puts "***Total Products: #{ products.count }***"
  puts "========================================"
end

# Execute crawler script
crawler
