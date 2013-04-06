require 'rubygems'
require 'sinatra'
require 'mongoid'
require 'bcrypt'
require 'yaml'
require 'base64'
require 'mongoid'
require 'mongo'
require './ruby/lib/dwolla-ruby.rb'
#require 'dwolla'

# REAL API ACCESS KEYS
APP_KEY   ="2vezPKWMkzzQC6vC1u+OPYED/fVxO1JTh2mNqljiDk6nB4so4c"
APP_SECRET="m5tL7eWao79w6cdSrS6jFhG0IQVwvPpmSibBMlSFy6RbKgskfk"

DwollaClient = Dwolla::Client.new(APP_KEY, APP_SECRET)

REDIRECT_URL="http://localhost:4567/dwolla/oauth"


configure do
	enable :sessions
	set :public_folder, Proc.new { File.join(root, "public") }
	# Mongoid.load!("mongoid.yml")
    Mongoid.configure do |config|
    config.sessions = {
      :default => {
        :hosts => ENV['MONGOHQ_URL'] || ["localhost:27017"],
        :database => "grabinero"
      }
    }
 	end

end

get '/testing' do
    authUrl = DwollaClient.auth_url(REDIRECT_URL)
    "To authorized, go <a target='_blank' href=\"#{authUrl}\">here</a>."
end

class Ask
	include Mongoid::Document
	field :item
	field :pending
end

get '/asksave/:item' do
	item = params[:item]
	ask = Ask.new(:item => item, :pending => true)
	ask.save

	"Hello I want #{ask.item}"
end

get '/askload/:item' do
	load_item = params[:item]
	ask = Ask.where(:item => load_item).first

	"Hello I loaded #{ask.item}"
end

helpers do
    def exists(username)
        if User.where(:username => username).first
            return true
        else
            return false
        end
    end

    def lesson_done(u_id)
        if Lesson.where(:u_id => u_id).first
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

get '/' do
    erb :index
end

get '/interview/:code' do
    @code = params[:code]
  erb :interview
end

get '/interview' do
    redirect '/interview/' + Base64.encode64(rand(1000000).to_s).chomp("=\n")
end

get '/lessons' do
  erb :lessons
end

get '/lessons/:lesson' do
    lesson = params[:lesson]
    if lesson == "lists"
        erb :lists
    elsif lesson == "stacks"
        erb :stacks
    elsif lesson == "trees"
        erb :trees
    end
end

get '/contact' do
  erb :contact
end

not_found do
  erb :error
end

post '/signup' do
    if not exists(params[:username])
        new_id = User.all.last.id + 1
        salt = BCrypt::Engine.generate_salt
        hash = BCrypt::Engine.hash_secret(params[:password], salt)
        User.create(id: new_id, username: params[:username], pass_salt: salt, pass_hash: hash)
        session[:username] = params[:username]
        redirect '/'
    else
        "this username exists already. go away"
    end
end

post '/login' do
    if exists(params[:username])
        user = User.where(:username => params[:username]).first
        if user.pass_hash == BCrypt::Engine.hash_secret(params[:password], user.pass_salt)
            session[:username] = params[:username]
            redirect '/dashboard'
        end
    end
    erb :error
end

get '/dashboard' do
    if !session[:username] then
        session[:previous_url] = request.path
        @error = 'Sorry but you must log in first'
        halt erb(:index)
    end
    @username = session[:username]
    erb :dashboard
end

get '/practice' do
    if !session[:username] then
        session[:previous_url] = request.path
        @error = 'Sorry but you must log in first'
        halt erb(:index)
    end
    @username = session[:username]
    erb :practice
end

get '/logout' do
    session[:username] = nil
    redirect '/'
end

get '/dwolla/demo' do
    "Token: #{session[:dwolla_token]}"
end

#
# OAuth Callback
#
get '/dwolla/oauth' do
    # if we have an error param OR we don't have an access token param...
    if !params[:error].nil? or params[:code].nil? then
        logger.error("Bad OAuth Request")
        return "Oh Noes! Bad times. #{params}"
    end

    code = params['code']
    logger.info(code)
    token = DwollaClient.request_token(code, REDIRECT_URL)
    logger.info(token)
    #session[:dwolla_token] = token
    #{}"Session #{session[:dwolla_token]}"
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
