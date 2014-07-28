require "bundler"
Bundler.require
Bundler.require :development if development?

require "sinatra/json"
require "open-uri"


get '/health' do
  json "ok"
end

post '/' do

	if params[:html].nil?
		status 400
		json "HTML chunk missing"	
	else

		html = Nokogiri::HTML(params[:html]) do |config|
			config.noblanks
		end

		if html.css("div[id='container']").text.size > 1
			process(html, "page")
		else
			process(html, "body")
		end

		jbuilder :response

	end

end

get '/' do

	if params[:url].nil? || !params[:url].include?("ewn.co.za") 
		status 400
		json "Missing or invalid EWN URL"
	
	else

		page = Nokogiri::HTML(open(params[:url])) do |config|
			config.noblanks
		end

		@title = page.css("meta[property='og:title']")[0]['content']
		@description = page.css("meta[property='og:description']")[0]['content']
		@author = page.css("meta[name='author']")[0]['content']
		@image = page.css("meta[property='og:image']")[0]['content']
		@url = params[:url]

		process(page, "page")

		jbuilder :response
	end
end

not_found do
	json "Invalid endpoint."
end

private

def process(content, type)

	if type == "page"

		article_body = content.css("span[itemprop='articleBody']")
		if article_body.text.size < 10
			article_body = content.css("article[class='feature']")
			article_body.css("aside").each do |aside|
				aside.remove
			end
		end

	elsif type == "body"

		article_body = content

	end

	@text = ""
	@markdown = ""
	@markup = ""
	@links = []
	@words = article_body.text.scan(/\w+/).size

	# exclude paragraph types on request
	excluded = ['empty']
	unless params[:exclude].nil?
		params[:exclude].split(",").map(&:strip).each do |exclude|
			excluded << exclude
		end
	end

	@paragraphs = []
	actual_paragraphs = article_body.inner_html.split(/<div.*>|<p style="text-align: center;">|<p>|<br><br>/).map(&:strip)
	paragraph_count = 0
	actual_paragraphs.each do |ap|
		if ap == '<blockquote lang="en" class="twitter-tweet">'
			actual_paragraphs[paragraph_count + 1].prepend(ap)
		else
			paragraph = paragraph_data(ap)
			unless excluded.include?(paragraph[:type])
				@paragraphs << paragraph
				@markdown += paragraph[:markdown]
				@markup += "<p>" + paragraph[:markup] + "</p>"
				unless paragraph[:plaintext].nil?
					@text += paragraph[:plaintext]
				end
			end
		end
		paragraph_count += 1
	end

end

def markdown_no_p(markdown)
	return Regexp.new('^<p>(.*)<\/p>$').match(markdown)[1]
end

def paragraph_data(html)

	# get rid of a bunch of leftovers
	html.slice! '<p style="text-align: center;">'
	html.slice! "<em></em>"
	html.slice! "</p>"
	html.slice! "<br>"
	html.slice! "</div>"

	# check for type of paragraph
	if html == "" || html.include?("Edited by") || html.include?("<small")
		type = "empty"
	elsif html.include?("vzaar video player")
		type = "video"
	elsif html.include?("www.youtube.com/embed")
		type = "youtube"
	elsif html.include?("<img")
		type = "image"
	elsif html.include?("twitter-tweet")
		type = "tweet"
	else
		type = "text"
	end

	# ignore empty paragraphs
	unless type == "empty"
		node = Nokogiri::HTML(html)
	end

	# set up basic properties of paragraph object
	paragraph = { }
	markup = { }
	data = { }
	paragraph[:type] = type
	markup = html

	case type
	when "video"
		paragraph[:subtype] = "vzaar"
		video = node.css("iframe")[0]['src']
		paragraph[:markdown] = "http:" + video
		data[:vzaar_id] = node.css("iframe")[0]['id'].gsub("vzvd-", "")
	when "youtube"
		paragraph[:type] = "video"
		paragraph[:subtype] = "youtube"
		video = node.css("iframe")[0]['src']
		paragraph[:markdown] = "http:" + video
	when "image"
		markdown = ReverseMarkdown.convert html
		paragraph[:markdown] = markdown
		data[:caption] = node.css("img")[0]['alt']
	when "tweet"
		markdown = ReverseMarkdown.convert html
		paragraph[:markdown] = markdown
		paragraph[:plaintext] = node.text
		links = []
		node.css("a").each do |a|
			if a['href'].include?('ewn.co.za')
				link_type = "internal"
			else
				link_type = "external"
			end
			link = { type: link_type, url: a['href'], text: a.text, target: a['target'] }
			links << link
			@links << link
		end
		unless links.size == 0
			data[:links] = links
		end
	when "text"
		markdown = ReverseMarkdown.convert html
		paragraph[:markdown] = markdown
		paragraph[:plaintext] = node.text
		if paragraph[:plaintext].size == 0
			paragraph[:type] = "empty"
		end
		if html[0..3] == "<em>"
			paragraph[:subtype] = "intro/outro"
		end
		links = []
		node.css("a").each do |a|
			unless a['href'].nil?
				if a['href'].include?('ewn.co.za')
					link_type = "internal"
				else
					link_type = "external"
				end
				link = { type: link_type, url: a['href'], text: a.text, target: a['target'] }
				links << link
				@links << link
			end
		end
		data[:words] = node.text.scan(/\w+/).size
		unless links.size == 0
			data[:links] = links
		end
	end

	# return a paragraph object to the paragraphs array
	paragraph[:markup] = markup
	paragraph[:data] = data

	return paragraph
end
