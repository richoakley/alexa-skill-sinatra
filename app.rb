require "bundler"
Bundler.require
Bundler.require :development if development?

require "sinatra/json"
require 'open-uri'

get '/health' do
  json "ok"
end

get '/' do

	if params[:url].nil? || !params[:url].include?("ewn.co.za") 
		status 400
		json "Missing or invalid EWN URL"
	
	else
		page = Nokogiri::HTML(open(params[:url])) do |config|
			config.noblanks
		end
		@url = params[:url]
		@title = page.css("meta[property='og:title']")[0]['content']
		@description = page.css("meta[property='og:description']")[0]['content']
		@author = page.css("meta[name='author']")[0]['content']
		@image = page.css("meta[property='og:image']")[0]['content']
		article_body = page.css("span[itemprop='articleBody']")

		# exclude paragraph types on request
		excluded = ['empty']
		unless params[:exclude].nil?
			params[:exclude].split(",").map(&:strip).each do |exclude|
				excluded << exclude
			end
		end

		@text = ""
		@markdown = ""
		@markup = { web: "", mobile: "", app: "" }
		@links = []
		@words = article_body.text.scan(/\w+/).size

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
					@markup[:web] += "<p>" + paragraph[:markup][:web] + "</p>"
					@markup[:mobile] += "<p>" + paragraph[:markup][:mobile] + "</p>"
					unless paragraph[:plaintext].nil?
						@text += paragraph[:plaintext]
					end
				end
			end
			paragraph_count += 1
		end


		jbuilder :response
	end
end

not_found do
	json "Invalid endpoint."
end

private

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
	if html == "" || html.include?("Edited by")
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
	markup[:web] = html

	case type
	when "video"
		video = node.css("iframe")[0]['src']
		paragraph[:markdown] = video
		markup[:mobile] = "<a href='#{video}' target='_blank'>Watch the video</a>"
		data[:vzaar_id] = node.css("iframe")[0]['id'].gsub("vzvd-", "")
	when "youtube"
		video = node.css("iframe")[0]['src']
		paragraph[:markdown] = "http:" + video
		markup[:mobile] = "<a href='http:#{video}' target='_blank'>Watch the video</a>"
	when "image"
		markdown = ReverseMarkdown.convert html
		paragraph[:markdown] = markdown
		mobile = Redcarpet::Markdown.new(Redcarpet::Render::HTML, autolink: true, tables: true)
		markup[:mobile] = markdown_no_p(mobile.render(markdown))
		data[:caption] = node.css("img")[0]['alt']
	when "tweet"
		markdown = ReverseMarkdown.convert html
		paragraph[:markdown] = markdown
		markup[:mobile] = markup[:web]
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
		markup[:mobile] = markup[:web]
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
