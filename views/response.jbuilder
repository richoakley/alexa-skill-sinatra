json.meta do
	json.url @url
	json.title @title
	json.description @description
	json.image @image
	json.author @author
	json.length do
		json.paragraphs @paragraphs.size
		json.words @words
	end
end

json.paragraphs @paragraphs do |paragraph|
	json.type paragraph[:type]
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

json.markup do
	json.web @markup[:web]
	json.mobile @markup[:mobile]
end