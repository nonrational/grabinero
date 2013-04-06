require 'rubygems'
require 'sinatra'
require 'sinatra/activerecord'
require 'bcrypt'
require 'yaml'
require 'base64'
require 'mongoid'
require 'mongo'

configure do
  enable :sessions
  set :database, "mysql2://b07682ab501ad3:11c2380c@us-cdbr-east-03.cleardb.com/heroku_0a79ab0c589a98e?reconnect=true"
  set :public_folder, Proc.new { File.join(root, "public") }
end

class User < ActiveRecord::Base
    attr_accessible :id, :username, :pass_salt, :pass_hash
end

class Lesson < ActiveRecord::Base
    attr_accessible :id, :u_id, :name, :progress
end

# Mongoid.configure do |config|
#   if ENV['MONGOHQ_URL']
#     conn = Mongo::Connection.from_uri(ENV['MONGOHQ_URL'])
#     uri = URI.parse(ENV['MONGOHQ_URL'])
#     config.master = conn.db(uri.path.gsub(/^\//, ''))
#   else
#     config.master = Mongo::Connection.from_uri("mongodb://localhost:27017").db('test')
#   end
# end

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
