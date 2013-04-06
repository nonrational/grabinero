require 'rubygems'
require 'sinatra'
require 'mongoid'
require 'bcrypt'
require 'yaml'
require 'base64'
require 'mongoid'
require 'mongo'
require 'uri'

class Ask
  include Mongoid::Document
  field :description, type: String
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
        :hosts => "localhost:27017",
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


get '/ask' do
  erb :_submit_ask
end

post '/ask/create' do
  ask = Ask.create(
    :description => params[:description],
    :email => params[:email],
    :pending => true,
  )
  redirect '/ask/show/pending'
end


get '/ask/show/all' do
  erb :asks, :locals => { :asks => Ask.order_by([[:createdDateTime, :desc]]) }
end
get '/ask/show/pending' do
  erb :asks, :locals => { :asks => Ask.where(:pending => true).order_by([[:createdDateTime, :desc]]) }
end
get '/ask/show/:id' do |id|
  erb :ask, :locals => { :ask => Ask.find(id) }
end
get '/ask/:id' do |id|
  ask = Ask.find(id)
  ask.to_json
end
delete 'ask/:id' do |id|
  Ask.find(id).destroy
end

post 'ask/:id/fulfill' do |id|
  #content_type :json  
  ask = Ask.find(id)
  if params[:email] then ask.add_to_set(params[:email]) end
  #ask.to_json
  erb :asks, :locals => { :asks => Ask.where(:pending => true) }
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

#
# OAuth Callback
#
post '/dwolla/oauth' do
    return reqlog('/dwolla/oauth', params)
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
