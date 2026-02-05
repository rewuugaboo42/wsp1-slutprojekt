require 'debug'
require "awesome_print"

class App < Sinatra::Base

    setup_development_features(self)

    # Funktion för att prata med databasen
    # Exempel på användning: db.execute('SELECT * FROM fruits')
    def db
      return @db if @db
      @db = SQLite3::Database.new(DB_PATH)
      @db.results_as_hash = true

      return @db
    end

    # Routen /
    get '/' do
      @products = db.execute("SELECT * FROM products")
      erb :index
    end

    get '/login' do
      erb :login
    end

    post '/login' do
      
    end

    get '/signup' do
      erb :signup
    end

    post '/signup' do
      redirect '/login'
    end

    get '/cart' do
      @cart_items = db.execute("SELECT * FROM cart_items")
      #redirect '/login' unless session[:user_id]
      erb :cart
    end

    post '/cart/add' do
      redirect '/login' unless session[:user_id]
      redirect '/'
    end

    post '/checkout' do
      #redirect '/login' unless session[:user_id]
      redirect '/orders'
    end

    get '/orders' do
      @orders = db.execute("SELECT * FROM orders")
      #redirect '/login' unless session[:user_id]
      erb :orders
    end

    get '/logout' do
      session.clear
      redirect '/'
    end
end