# siteconfig.rb

# REAL API ACCESS KEYS
APP_KEY   ="2vezPKWMkzzQC6vC1u+OPYED/fVxO1JTh2mNqljiDk6nB4so4c"
APP_SECRET="m5tL7eWao79w6cdSrS6jFhG0IQVwvPpmSibBMlSFy6RbKgskfk"

DwollaClient = Dwolla::Client.new(APP_KEY, APP_SECRET)

$state = [:pending, :promised, :fulfilled, :completed]
$code_of_state = Hash[$state.map.with_index.to_a]

class GrabTask
    include Mongoid::Document
    field :creatorName, type: String
    field :creatorId, type: String
    field :responderName, type: String
    field :responderId, type: String
    field :state, type: Integer
    field :createdDateTime, type: DateTime, default: ->{ DateTime.now }
    field :item, type: String
    field :location, type:String
    field :timespan, type: String
end

configure :development do
    enable :sessions
    set :public_folder, Proc.new { File.join(root, "public") }
    Mongoid.configure do |config|
    config.sessions = {
        :default => {
            :hosts => ["localhost:27017"],
            :database => "grabinero"
        }
    }

    REDIRECT_URL="http://localhost:4567/dwolla/oauth"

    end
end

configure :production do
    enable :sessions
    set :public_folder, Proc.new { File.join(root, "public") }
    uri  = URI.parse(ENV['MONGOLAB_URI'])
    conn = Mongo::Connection.from_uri(ENV['MONGOLAB_URI'])
    db   = conn.db(uri.path.gsub(/^\//, ''))
    db.collection_names.each { |name| puts name }
    REDIRECT_URL="http://www.grabinero.com/dwolla/oauth"
end

helpers do
    def fulfill_url(ask)
        "/ask/#{id}/fulfill"
    end

    def show_url(ask)
        "/ask/show/#{id}"
    end

    def logged_in()
        return session[:dwolla_token] != nil
    end
end
