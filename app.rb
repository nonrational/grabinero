require 'rubygems'
require 'sinatra'
require 'mongoid'
require 'bcrypt'
require 'yaml'
require 'base64'
require 'mongoid'
require 'mongo'
require 'uri'
require './ruby/lib/dwolla-ruby.rb'
require 'pp'

# REAL API ACCESS KEYS
APP_KEY   ="2vezPKWMkzzQC6vC1u+OPYED/fVxO1JTh2mNqljiDk6nB4so4c"
APP_SECRET="m5tL7eWao79w6cdSrS6jFhG0IQVwvPpmSibBMlSFy6RbKgskfk"

DwollaClient = Dwolla::Client.new(APP_KEY, APP_SECRET)

REDIRECT_URL="http://localhost:4567/dwolla/oauth"
# REDIRECT_URL="http://www.grabinero.com/dwolla/oauth"

state = [:pending, :promised, :fulfilled, :completed]
code_of_state = Hash[state.map.with_index.to_a]

class Ask
  include Mongoid::Document
  field :description, type: String
  field :name, type: String
  field :email, type: String
  field :fulfiller, type: String
  field :state, type: Integer
  field :createdDateTime, type: DateTime, default: ->{ DateTime.now }
end

configure :development do
  enable :sessions
  set :public_folder, Proc.new { File.join(root, "public") }
  Mongoid.load!("mongoid.yml")
  Mongoid.configure do |config|
    config.sessions = {
      :default => {
        :hosts => ["localhost:27017"],
        :database => "grabinero"
      }
    }
  end
end

configure :production do
  enable :sessions
  set :public_folder, Proc.new { File.join(root, "public") }
  uri  = URI.parse(ENV['MONGOLAB_URI'])
  conn = Mongo::Connection.from_uri(ENV['MONGOLAB_URI'])
  db   = conn.db(uri.path.gsub(/^\//, ''))
  db.collection_names.each { |name| puts name }
end

before do
  puts '[Params]'
  p params
end

helpers do
  def fulfill_url(ask)
    "/ask/#{id}/fulfill"
  end
  def show_url(ask)
    "/ask/show/#{id}"
  end
  def exists(username)
    if User.where(:username => username).first
      return true
    else
      return false
    end
  end

  def login?
    if session[:username].nil?
      return false
    else
      return true
    end
  end

  def username
    return session[:username]
  end
end

get '/ask' do
  erb :_submit_ask
end

post '/ask' do
  ask = Ask.create(
    :description => params[:description],
    :name => params[:name],
    :email => params[:email],
    :state => code_of_state[:pending],
  )
  redirect '/asks/pending'
end

get '/asks' do
  erb :asks, :locals => { :asks => Ask.order_by([[:createdDateTime, :desc]]) }
end

get '/asks/pending' do
  erb :asks, :locals => { :asks => Ask.where(:state => code_of_state[:pending]).order_by([[:createdDateTime, :desc]]) }
end

get '/ask/:id' do |id|
  erb :_ask, :locals => { :ask => Ask.find(id) }
end

=begin
get '/ask/:id' do |id|
  ask = Ask.find(id)
  ask.to_json
end
=end

delete 'ask/:id' do |id|
  Ask.find(id).destroy
end

post 'ask/:id/fulfill' do |id|
  #content_type :json
  ask = Ask.find(id)
  if params[:email]
    ask.fulfiller = params[:email]
    ask.state = code_of_state[:promised]
  else
    erb :error
  end
  #ask.to_json
  redirect '/asks/pending'
end

get '/' do
  erb :index
end

not_found do
  erb :error
end

# attempt to login if needed. otherwise, noop.
get '/login' do
    if session[:dwolla_token].nil? then
        redirect DwollaClient.auth_url(REDIRECT_URL)
    end
end

# remove the dwollo token from your session
get '/logout' do
    session[:dwolla_token] = nil
    redirect '/'
end

# Print the currently OAuth'd user's name
get '/user' do
    DwollaUser = Dwolla::User.me(session[:dwolla_token])
    DwollaUser.fetch
    erb "#{DwollaUser.name}"
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
