require "nokogiri"
require "httparty"

def print_arr(array)
  print("Here are the games on sale right now:\n")

  (0...array.size).each do |i|
    array[i][1].slice!(array[i][2])
    array[i][1]
    puts "#{i+1}: #{array[i][0]} - #{array[i][1]} - usually #{array[i][2]} - rating #{array[i][4][0]}% positive with #{array[i][4][1]} voters"
  end
end
class Scraper

  def initialize
    doc=HTTParty.get("https://store.steampowered.com/search/?filter=weeklongdeals")
    @parse_page ||= Nokogiri::HTML(doc);
  end

  def get_titles
    elements=@parse_page.css('.search_results').css('.responsive_search_name_combined').css('.col.search_name.ellipsis').css('.title')
  end

  def get_prices
    prices=@parse_page.css('.search_results').css('.responsive_search_name_combined').css('.col.search_price_discount_combined.responsive_secondrow').css('.col.search_price.discounted.responsive_secondrow')
  end

  def get_discounts
    discounts=@parse_page.css('.search_results').css('.responsive_search_name_combined').css('.col.search_price_discount_combined.responsive_secondrow').css('.col.search_price.discounted.responsive_secondrow').css('strike')
  end

  def get_href
    href=@parse_page.css('.search_results').css("a[href]")
  end

  def get_revs
    revs=@parse_page.css('.search_results').css('.responsive_search_name_combined').css('.col.search_reviewscore.responsive_secondrow')
  end

  def perc_off
    perc=@parse_page.css('.search_results').css('.responsive_search_name_combined').css('.col.search_price_discount_combined.responsive_secondrow').css('.col.search_discount.responsive_secondrow')
  end

  def option1(array)
    puts "Enter the index of the game you would like to know more about : "
    index=gets.chomp.to_i
    game=array[index-1][3]
    specific_page(array[index-1][0],game)
  end

  def specific_page(title, link)
    page=HTTParty.get(link)
    @new_page= Nokogiri::HTML(page);

    description=@new_page.css(".responsive_page_frame.with_header").css(".responsive_page_content").css(".responsive_page_template_content").css(".page_content_ctn").css(".block").css(".game_background_glow").css(".block_content.page_content").css(".rightcol").css(".glance_ctn").css(".game_description_snippet").text.tr("\t","").tr("\r\n", "")
    developer=@new_page.css(".responsive_page_frame.with_header").css(".responsive_page_content").css(".responsive_page_template_content").css(".page_content_ctn").css(".block").css(".game_background_glow").css(".block_content.page_content").css(".rightcol").css(".glance_ctn").css(".glance_ctn_responsive_left").css(".user_reviews").css(".dev_row").css(".summary.column").text.tr("\t\n", "").split("\r")
    tags=@new_page.css(".responsive_page_frame.with_header").css(".responsive_page_content").css(".responsive_page_template_content").css(".page_content_ctn").css(".block").css(".game_background_glow").css(".block_content.page_content").css(".rightcol").css(".glance_ctn").css(".glance_ctn_responsive_right").css(".glance_tags_ctn.popular_tags_ctn").css(".glance_tags.popular_tags").text.tr("\t\n", "").split("\r")
    puts "Here is the info for the game you selected"
    print("Name: ")
    puts title
    print("Developer: ")
    puts developer[1]
    print("Publisher: ")
    puts developer[2]
    print("Description: ")
    puts (description)
    print("Tags: ")
    puts "#{tags[2]}, #{tags[3]}, #{tags[4]}"

  end
  
  scraper=Scraper.new
  discounts=scraper.get_discounts
  titles=scraper.get_titles
  prices=scraper.get_prices
  hrefs=scraper.get_href
  revs=scraper.get_revs
  percs=scraper.perc_off

  array_price=[]
  array_discount=[]
  array_title=[]
  array_href=[]
  array_ratings=[]
  array_percs=[]

  prices.each do |price|
    price.children.each do |child|
     if child.name == 'text' && !child.text.strip.empty?
       array_price.push(price.text.tr(" ","").tr("\r\n", ""))
      end
    end
  end
  discounts.each do |discount|
    array_discount.push(discount.text)
  end

  titles.each do |title|
    array_title.push(title.text)
  end

  hrefs.each do |href|
    array_href.push(href["href"])
  end

  revs.each do|rev|
    rating= rev.css('.search_review_summary.positive').attr('data-tooltip-html').to_s.tr("abcdefghijklmnopqrstuvwxyz<> ABCDEFGHIJKLMNOPQRSTUVWXYZ.","").split("%")
    rating= ((rev.css('.search_rqeview_summary.mixed').attr('data-tooltip-html').to_s) + (rev.css('.search_review_summary.positive').attr('data-tooltip-html').to_s) + (rev.css('.search_review_summary.negative').attr('data-tooltip-html').to_s)).tr("abcdefghijklmnopqrstuvwxyz<> ABCDEFGHIJKLMNOPQRSTUVWXYZ.","").split("%")
    array_ratings.push(rating)
  end

  percs.each do |perc|
    array_percs.push(perc.text.tr(" \r\n-%", ""))
  end
  array=[]

  (0...array_title.size).each do |i|
    array_element=[]
    array_element.push(array_title[i])
    array_element.push(array_price[i])
    array_element.push(array_discount[i])
    array_element.push(array_href[i])
    array_element.push(array_ratings[i])
    array_element.push(array_percs[i])
    array.push(array_element)
  end
  array = array.sort {|a,b| a[5] <=> b[5]}.reverse
  print_arr(array)
  #puts array
  choice =0
  while choice!=-1
    
    puts "\nMenu"
    puts "1. Open description of game"
    puts "2. Sort by "
    puts "3. Print list"
    puts "-1. Quit"
    
    print("Enter choice: ")
    choice=gets.chomp.to_i
    
    if(choice==1)
      scraper.option1(array)

    elsif(choice ==2)
      puts "  What will you sort by?"
      puts "  a. Ratings"
      puts "  b. Discount (%)"
      puts "  c. Discount ($)"
      puts "  d. Price"
      puts "  e. Cancel"
      print "  Enter choice:"
      choice_sort=gets.chomp.to_s
      sorted_array=[]

      if choice_sort=="a"
        sorted_array=array.sort {|a,b| a[4] <=> b[4]}.reverse
        print_arr(sorted_array)

      elsif choice_sort=="b"
        sorted_array=array.sort {|a,b| a[5] <=> b[5]}.reverse
        print_arr(sorted_array)

      elsif choice_sort=="c"
        sorted_array=array.sort {|a,b| (a[2].tr("$", "").to_f-a[1].tr("$", "").to_f) <=> (b[2].tr("$", "").to_f-b[1].tr("$", "").to_f)}.reverse
        print_arr(sorted_array)

      elsif choice_sort=="d"
        sorted_array=array.sort {|a,b| a[1].tr("$", "").to_f <=> b[1].tr("$", "").to_f}
        print_arr(sorted_array)
      end

    elsif(choice==3)
      print_arr(array)
    end
  end
end


#@parse_page.css('.search_results').css('.responsive_search_name_combined').css('.col.search_reviewscore.responsive_secondrow').css('.search_review_summary.mixed').first.attr('data-tooltip-html')