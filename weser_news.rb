require 'twitter'
require 'uri'
require 'open-uri'
require 'nokogiri'
require 'htmlentities'

load 'twitter_config.rb'

def cleanup
  files_to_delete = ["articles.tex", "articles.aux", "template.aux", "template.toc", "template.log", "template.out"]

  files_to_delete.each do |file|
    File.delete(file) if File.exist?(file)
  end
end

class Article
  attr_accessor :title
  attr_accessor :author
  attr_accessor :summary
  attr_accessor :text

  def initialize()
    @title = ""
    @author = ""
    @summary = ""
    @text = ""
  end
end

# fetch tweets by WESER_KURIER
tweets = $client.user_timeline("WESER_KURIER")

# extract links from tweets
links = []
tweets.each do |tweet|
  content = URI.extract(tweet.text)

  # convert each result to an array 
  if content.kind_of?(String)
    content = [content]
  end

  # check each item if it is a link
  content.each do |item|
    if item.start_with?("http://")
      links.push(item)
    end
  end
end

articles = []

links.each do |link|
  # make new article
  a = Article.new

  # extract information from website
  begin
    html_doc  = Nokogiri::HTML(open(link))
    a.title   = HTMLEntities.new.decode html_doc.to_s.match(/title: "(.+)"/)[1]
    a.summary = HTMLEntities.new.decode html_doc.xpath("string(//p[contains(@class, 'article_teaser')])")

    # skip image links
    next if a.title.size == 0 || a.summary.size == 0

    a.author = HTMLEntities.new.decode html_doc.xpath("//span[contains(@class, 'authors-name')]")
    article_pars = html_doc.xpath("//div[contains(@id, 'onlineText')]").children
    
    article_pars.each do |par|
      par.content.gsub!("\n", "")
      par.content.gsub!(/[\u0080-\u00ff]/, "")
      par.content.gsub!(/[\u8000]/, "")
      if  par.content.size > 0
        a.text += HTMLEntities.new.decode par.content
        a.text += "\n"
      end
    end

    # fix some characters latex has problems with
    a.text = a.text.gsub("&", "und")
    a.text = a.text.gsub("\n\n","\n")
    a.summary = a.summary.gsub("\n", "")

    # skip if no article text
    next if a.text.size == 0 

    articles.push(a)
  rescue => e
    case e
    when OpenURI::HTTPError
      puts "HTTPError occured while processing link #{link}. Program will ignore this one."
    when SocketError
      puts "SocketError occured while processing link #{link}. Program will ignore this one."
    else
      puts "Something unexspected happend while processing link #{link}. Program will ignore this one."
    end
  end
end

# export articles to tex file
file = File.new("articles.tex", 'w')
articles.each do |article|
  file.write("\\section{#{article.title}}\n")
  file.write("\n")
  file.write("\\textbf{#{article.summary}}")
  file.write("#{article.text}")
end
file.close

# build newspaper
2.times do 
  system( "pdflatex template.tex" )
end

cleanup

