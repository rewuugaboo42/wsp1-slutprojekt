require 'debug'
require "awesome_print"
require 'bcrypt'
require_relative 'models/user'
require_relative 'models/cart'
require_relative 'models/order'
require_relative 'models/product'

class App < Sinatra::Base
  enable :sessions
  use Rack::Session::Cookie, 
    key: 'rack.session',
    path: '/',
    secret: "cf22c9d6061b3e067155e59d775d4406c92b6afc4aaff0a4131e9165eb2d492b597ace501a3df36043ecba99ae29474acac0cbd8c75fb5f46503b3e90d8b8159"


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
    @products = Product.all(db)
    erb :index
  end

  get '/login' do
    erb :login
  end

  post '/login' do
    login_email = params["email"]
    login_password = params["password"]

    user = User.find_by_email(login_email, db)
    
    if user && BCrypt::Password.new(user.password_hash) == login_password
      session[:user_id] = user.user_id
      redirect '/'
    else
      @error = "Wrong email or password"
      erb :login
    end
  end

  get '/signup' do
    erb :signup
  end

  post '/signup' do
    signup_username = params["username"]
    signup_email = params["email"]
    signup_password = params["password"]

    user = User.find_by_username_or_email(signup_username, signup_email, db)

    if user
      @error = "Username or email already exists"
      return erb :signup
    else
      User.create(signup_username, signup_email, signup_password, db)
      redirect '/login'
    end   
  end

  get '/cart' do
    redirect '/login' unless session[:user_id]

    cart = Cart.find_or_create_by_user(session[:user_id], db)
    @cart_items = cart.items(db)

    erb :cart
  end

  post '/cart/add' do
    redirect '/login' unless session[:user_id]

    product_id = params["product_id"].to_i
    quantity   = (params["quantity"] || 1).to_i

    cart = Cart.find_or_create_by_user(session[:user_id], db)
    cart.add_item(product_id, quantity, db)

    redirect '/cart'
  end

  post '/checkout' do
    redirect '/login' unless session[:user_id]

    cart = Cart.find_or_create_by_user(session[:user_id], db)
    Order.create_from_cart(cart, db, session[:user_id])

    redirect '/orders'
  end

  get '/orders' do
    redirect '/login' unless session[:user_id]

    @orders = Order.for_user(session[:user_id], db)

    erb :orders
  end

  get '/logout' do
    session.clear
    redirect '/'
  end
end