json.meta do
	json.url @url if @url
	json.title @title if @title
	json.description @description if @description
	json.image @image if @image
	json.author @author if @author
	json.length do
		json.paragraphs @paragraphs.size
		json.words @words
	end
end

json.paragraphs @paragraphs do |paragraph|
	json.type paragraph[:type]
	json.subtype paragraph[:subtype] if paragraph[:subtype]
	json.markdown paragraph[:markdown]
	json.markup paragraph[:markup]
	unless paragraph[:plaintext].nil?
		json.plaintext paragraph[:plaintext]
	end
	unless paragraph[:data].nil?
		json.data paragraph[:data]
	end
end

json.plaintext @text

json.markdown @markdown

json.markup @markup