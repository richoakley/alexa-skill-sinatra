require "bundler"
Bundler.require
Bundler.require :development if development?

require "sinatra/json"

get '/health' do
  json "ok"
end

post '/' do

	# valid Alexa request?
  query_json = JSON.parse(request.body.read.to_s)
  # create a 'query' object from the request
  query = AlexaRubykit.build_request(query_json)

  # capture session info
  session = query.session
  p session.new?
  p session.has_attributes?
  p session.session_id
  p session.user_defined?

  # reply object
  reply = AlexaRubykit::Response.new

  if (query.type == 'LAUNCH_REQUEST')
    # load session into DB etc
    reply.add_speech('Hello!')
  end

  if (query.type == 'INTENT_REQUEST')

    p "#{query.slots}"
    p "#{query.name}"

    case query.name
    when "NameOfIntent"
    	# you probably want some logic depending on the different intents
    else
    	# fallback
    end

    # the speech response
    reply.add_speech("I received an intent named #{query.name}?")
    # the card response (for the Alexa app)
    reply.add_hash_card( { :title => 'Skill Intent', :subtitle => "Intent #{query.name}" } )

    # here is a 'Standard' card, which includes an image:
    # reply.add_hash_card( { :type => "Standard", :title => "Alexa Skill", :subtitle => "Intent #{query.name}", :image => { :small => "small_url", :large => "large_url" } } )

  end

  if (query.type =='SESSION_ENDED_REQUEST')
    # Wrap up sessions etc
    p "#{query.type}"
    p "#{query.reason}"
    halt 200
  end

  # Return response
  response.content_type = "application/json"
	response.body = reply.build_response

end

not_found do
	json "Invalid endpoint."
end