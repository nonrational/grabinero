require 'rubygems'
require 'sinatra'
require 'mongoid'
require 'bcrypt'
require 'yaml'
require 'base64'

configure do
  enable :sessions
  set :public_folder, Proc.new { File.join(root, "public") }
    Mongoid.configure do |config|
    config.sessions = { 
      :default => {
        :hosts => ENV['MONGOHQ_URL'] || ["localhost:27017"],
        :database => "grabinero"
      }
    }
  end
end

#class User < ActiveRecord::Base
#attr_accessible :id, :username, :pass_salt, :pass_hash
#end

#class Lesson < ActiveRecord::Base
#attr_accessible :id, :u_id, :name, :progress
#end


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
