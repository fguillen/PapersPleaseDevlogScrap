require "httparty"
require "nokogiri"
require "erb"


class Script
  TEMPLATE_PATH_INDEX = "#{__dir__}/templates/index.erb"

  RESULT_PATH = "#{__dir__}/index.html"
  CACHE_PATH = "#{__dir__}/cache.html"

  def run
    File.truncate(RESULT_PATH, 0)

    template_index = File.read(TEMPLATE_PATH_INDEX)
    html = nil
    if(File.exists?(CACHE_PATH))
      puts "Using cache!"
      html = File.read(CACHE_PATH)
    else
      response = HTTParty.get("https://forums.tigsource.com/index.php?topic=29750.0")
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
      id = datetime.strftime("%Y%m%d%H%M")

      content = element.css("div.post")
      content = clean_content(content, doc)


      html = "<h1>#{date}</h1>"
      html += content.inner_html


      puts "Date: #{date}"

      articles << {
        id: id,
        date: date,
        time: time,
        content: content.inner_html
      }
    end

    erb = ERB.new(template_index)
    html = erb.result_with_hash(articles: articles)

    File.open(RESULT_PATH, "w") { |f| f.write html }
  end

  def clean_date(date)
    date.gsub(/.*on: /, "").gsub(" »", "")
  end

  def clean_content(content, doc)
    content.css("div.quoteheader").remove

    content.css("div.quote").each do |div|
      new_node = doc.create_element "blockquote"
      new_node.inner_html = div.inner_html
      div.replace new_node
    end

    content
  end
end

Script.new.run
