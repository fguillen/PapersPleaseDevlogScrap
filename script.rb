require "httparty"
require "nokogiri"


class Script
  RESULT_FILE_PATH = "#{__dir__}/index.html"

  def run
    File.truncate(RESULT_FILE_PATH, 0)

    response = HTTParty.get("https://forums.tigsource.com/index.php?topic=29750.0")
    html = response.body
    doc = Nokogiri::HTML(html)
    elements = doc.css("td.windowbg")
    dukope_elements = elements.select { |e| e.css("a").first["title"] == "View the profile of dukope" }

    dukope_elements.each do |element|
      date = element.css("div.smalltext")[1].text
      date = clean_date(date)

      content = element.css("div.post")
      content = clean_content(content, doc)


      html = "<h1>#{date}</h1>"
      html += content.inner_html


      puts "Date: #{date}"
      File.open(RESULT_FILE_PATH, "a") { |f| f.write html }
    end
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
