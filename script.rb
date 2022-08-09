require "httparty"
require "nokogiri"
require "erb"

class Script
  TEMPLATE_PATH_INDEX = "#{__dir__}/templates/index.erb"
  RESULT_PATH = "#{__dir__}/index.html"
  CACHE_PATH = "#{__dir__}/cache.html"
  BASE_URL = "https://forums.tigsource.com/index.php?topic=29750"
  USE_CACHE = false

  def run
    pages = (0..700).step(20).to_a

    articles = []

    pages.each do |page|
      articles.concat parse_page(page)
    end

    render_erb(articles)
  end

  def render_erb(articles)
    # puts "articles: #{JSON.pretty_generate articles}"
    template_index = File.read(TEMPLATE_PATH_INDEX)
    erb = ERB.new(template_index)

    articles_month = articles.group_by { |e| e[:month] }

    # puts "articles_month: #{articles_month}"s


    html = erb.result_with_hash(articles_month: articles_month)

    File.open(RESULT_PATH, "w") { |f| f.write html }
  end

  def parse_page(page)
    puts "Page: #{page}"
    html = nil
    if(USE_CACHE && File.exists?(CACHE_PATH))
      puts "Using cache!"
      html = File.read(CACHE_PATH)
    else
      response = HTTParty.get("#{BASE_URL}.#{page}")
      html = response.body
      File.open(CACHE_PATH, "w") { |f| f.write html }
    end

    doc = Nokogiri::HTML(html)
    elements = doc.css("td.windowbg")
    dukope_elements = elements.select { |e| e.css("a").first["title"] == "View the profile of dukope" }

    articles = []

    dukope_elements.each do |element|
      datetime = element.css("div.smalltext")[1].text
      datetime = DateTime.parse(clean_date(datetime))

      date = datetime.strftime("%Y %B %d")
      time = datetime.strftime("%H:%M")
      month = datetime.strftime("%Y %B")
      id = datetime.strftime("%Y%m%d%H%M")

      content = element.css("div.post")
      content = clean_content(content, doc)

      puts "Id: #{id}"

      articles << {
        id: id,
        datetime: datetime,
        date: date,
        time: time,
        month: month,
        content: content.inner_html
      }
    end

    articles
  end

  def clean_date(date)
    date.gsub(/.*on: /, "").gsub(" »", "")
  end

  def clean_content(content, doc)
    content.css("div.quoteheader").remove

    content.css("div.quote").each do |div|
      new_node = doc.create_element("blockquote", { class: "blockquote" })
      new_node.inner_html = div.inner_html
      div.replace new_node
    end

    content
  end
end

Script.new.run
