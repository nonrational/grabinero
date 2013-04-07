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

get '/'   do erb :index end
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
            :location => params[:location]
        )
        redirect '/asks/pending'
    end
end

# # actually create the ask
# post '/solicit' do
#   ask = GrabTask.create(
#     :name => DwollaUser.name,
#     :creatorId => DwollaUser.email,
#     :state => code_of_state[:pending],
#     :description => params[:description],
#   )
#   redirect '/asks/pending'
# end

get '/asks' do
  erb :asks, :locals => { :asks => GrabTask.order_by([[:createdDateTime, :desc]]) }
end

get '/asks/pending' do
  erb :asks, :locals => { :asks => GrabTask.where(:state => $code_of_state[:pending]).order_by([[:createdDateTime, :desc]]) }
end

get '/ask/:id' do |id|
  erb :_ask, :locals => { :ask => GrabTask.find(id) }
end

delete 'ask/:id' do |id|
  GrabTask.find(id).destroy
end

post 'ask/:id/fulfill' do |id|
    if not logged_in() then
        redirect "/error"
    else
    # find the grabtask you're looking for
        ask = GrabTask.find(id)

        ask.fulfillerId = params[:dwolla_id]
        ask.state = $code_of_state[:promised]

        redirect '/asks/pending'
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

    session[:name] = DwollaUser.name
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
