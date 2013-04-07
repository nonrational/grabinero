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
require 'net/http'

Mongoid.load!("config/mongoid.yml")
DwollaClient = Dwolla::Client.new(APP_KEY, APP_SECRET)

def transaction_matches_task(txnData, taskData)
    found = (txnData[:fromId] == taskData.creatorId and
             txnData[:toId] == taskData.responderId and
             txnData[:amount] ==  taskData.amount.to_f)
    # logger.info(found)
    return found
end

get '/' do
    if not logged_in() then
        erb :brochure
    else
        # get all the completed transactions
        txns = get_transactions
        txnDatas = []
        txns['Response'].each do |txn|
            txndata = {
                id:txn['Id'],
                fromId:txn['SourceId'],
                toId:txn['DestinationId'],
                amount:txn['Amount']
                # , date:txn['Date'].nil? ? nil : Date.parse(txn['Date'])
            }
            txnDatas.push(txndata)
        end

        pp txnDatas

        GrabTask.where(:state => $code_of_state[:fulfilled]).each do |task|
            txnDatas.each do |txnData|
                if transaction_matches_task(txnData, task)
                    # logger.info("MATCHES")
                    task.update_attribute(:state, $code_of_state[:completed])
                    task.save
                end
            end
        end

        #
        erb :index, :locals => { :asks => GrabTask.not_in(:state => $code_of_state[:completed]).order_by([[:createdDateTime, :desc]]) }
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

post '/ask/*/promise' do
    id = params[:splat]

    if not logged_in() then
        redirect "/error"
    else
        # find the grabtask you're looking for
        ask = GrabTask.find(id).first
        # pp ask
        ask.update_attribute(:responderName, session[:name])
        ask.update_attribute(:responderId, session[:dwolla_id])
        ask.update_attribute(:state, $code_of_state[:promised])
        ask.save
        redirect '/'
    end
end

post '/ask/*/fulfill' do
    id = params[:splat]
    amt = params[:amount]
    pin = params[:pin]

    if not logged_in() then
        redirect "/error"
    else
        # find the grabtask you're looking for
        ask = GrabTask.find(id).first
        begin
            amount = (amt.to_f + 1.0);
            txnId = Dwolla::User.me(session[:dwolla_token]).request_money_from(ask.creatorId, amount, pin)
            ask.update_attribute(:state, $code_of_state[:fulfilled])
            ask.update_attribute(:transactionId, txnId)
            ask.update_attribute(:amount, amount)
            ask.update_attribute(:fulfilledDateTime, DateTime.now)
            ask.save
            redirect '/'
        rescue
            redirect "/error"
        end
        # pp ask
    end
end

#
# OAuth Callback
#
get '/dwolla/oauth' do
    # if we have an error param OR we don't have an access token param...
    if not params[:error].nil? or params[:code].nil? then
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


def get_transactions()
    uri = URI.parse("https://www.dwolla.com/oauth/rest/transactions/")
    args = {oauth_token: session[:dwolla_token], client_id:APP_KEY, client_secret:APP_SECRET}
    uri.query = URI.encode_www_form(args)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    request = Net::HTTP::Get.new(uri.request_uri)
    response = http.request(request)
    json = JSON.parse(response.body)
end
