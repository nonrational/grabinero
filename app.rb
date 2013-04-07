require 'rubygems'
require 'sinatra'
require 'mongoid'
require 'bcrypt'
require 'yaml'
require 'base64'
require 'mongoid'
require 'mongo'
require 'uri'
require 'pp'
require './ruby/lib/dwolla-ruby.rb'
require "./siteconfig.rb"

Mongoid.load!("config/mongoid.yml")
DwollaClient = Dwolla::Client.new(APP_KEY, APP_SECRET)

get '/'   do
    if not logged_in() then
        erb :brochure
    else
        # .where(:state => $code_of_state[:pending] )
        erb :index, :locals => { :asks => GrabTask.order_by([[:createdDateTime, :desc]]) }
    end
end
not_found do erb :error end

# delegate to dwolla to handle login
get '/login' do
    if session[:dwolla_token].nil? then
        redirect DwollaClient.auth_url(REDIRECT_URL)
    else
        erb session[:dwolla_token]
    end
end

# clear session on logout
get '/logout' do
    session.clear
    redirect '/'
end

# show the submit form
get '/ask' do
  erb :_submit_ask, :locals => { :name => session[:name] }
end

# actually create the ask
post '/ask' do
    if not logged_in() then
        redirect '/error'
    else
        ask = GrabTask.create(
            :creatorName => session[:name],
            :creatorId => session[:dwolla_id],
            :state => $code_of_state[:pending],
            :description => params[:description],
            :location => params[:location],
        )
        redirect '/'
    end
end

# actually create the ask
post '/solicit' do
  if not logged_in() then
        redirect '/error'
    else
        ask = GrabTask.create(
            :creatorName => session[:name],
            :creatorId => session[:dwolla_id],
            :state => $code_of_state[:pending],
            :location => params[:destination],
            :timespan => params[:time],
            :ask => false
        )
        redirect '/'
    end
end

# get '/asks' do
#   erb :asks, :locals => { :asks => GrabTask.order_by([[:createdDateTime, :desc]]) }
# end

# get '/asks/pending' do
#   erb :asks, :locals => { :asks => GrabTask.where(:state => $code_of_state[:pending]).order_by([[:createdDateTime, :desc]]) }
# end

# get '/ask/:id' do |id|
#   erb :_ask, :locals => { :ask => GrabTask.find(id) }
# end

# delete 'ask/:id' do |id|
#   GrabTask.find(id).destroy
# end

post '/ask/*/fulfill' do
    id = params[:splat]

    if not logged_in() then
        redirect "/error"
    else
        # find the grabtask you're looking for
        ask = GrabTask.find(id).first
        # pp ask
        ask.update_attribute(:responderName, session[:name])
        ask.update_attribute(:responderId, session[:dwolla_id])
        ask.update_attribute(:state, $code_of_state[:fulfilled])
        ask.save
        redirect '/'
    end
end


# Print the currently OAuth'd user's name
# Testing only
get '/user' do
    if not logged_in() then
        erb "Not logged in! <a href='/login'>Please login here</a>"
    else
        erb "Hi #{session[:name]} (id:#{session[:dwolla_id]})"
    end
end

#
# OAuth Callback
#
get '/dwolla/oauth' do
    # if we have an error param OR we don't have an access token param...
    if !params[:error].nil? or params[:code].nil? then
        logger.error("Bad OAuth Request")
        erb "Oh Noes! Bad times. Got: #{params}"
    end

    token = DwollaClient.request_token(params['code'], REDIRECT_URL)
    DwollaUser = Dwolla::User.me(token).fetch

    session[:name] = DwollaUser.name.split.first
    session[:dwolla_id] = DwollaUser.id
    session[:dwolla_token] = token

    redirect "/"
end

#
# Payment Information Callback
#
post '/dwolla/payment' do
  return reqlog('/dwolla/payment', params)
end

#
# Payment Success Callback
#
post '/dwolla/success' do
  return reqlog('/dwolla/payment', params)
end

#
# Request and Log
#
def reqlog(path, params)
  logger.info("#{path} #{params}")
  return "#{path} #{params}"
end
