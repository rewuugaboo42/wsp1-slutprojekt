require 'debug'
require "awesome_print"
require 'bcrypt'

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
    @products = db.execute("SELECT * FROM products")
    erb :index
  end

  get '/login' do
    erb :login
  end

  post '/login' do
    login_email = params["email"]
    login_password = params["password"]

    user = db.execute("SELECT * FROM users WHERE email = ?", login_email).first
    
    if user && BCrypt::Password.new(user["password_hash"]) == login_password
      session[:user_id] = user["user_id"]
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

    user = db.execute("SELECT * FROM users WHERE username = ? OR email = ?", [signup_username, signup_email]).first

    if user
      @error = "Username or email already exists"
      erb :signup
    else
      password_hash = BCrypt::Password.create(signup_password)

      db.execute("INSERT INTO users (username, email, password_hash) VALUES (?, ?, ?)", [signup_username, signup_email, password_hash])
    end   

    redirect '/login'
  end

  get '/cart' do
    redirect '/login' unless session[:user_id]
    @cart_items = db.execute(
      <<~SQL, [session[:user_id]]
        SELECT ci.cart_item_id, ci.quantity, p.product_id, p.name, p.price, p.image_url
        FROM cart_items ci
        JOIN carts c ON ci.cart_id = c.cart_id
        JOIN products p ON ci.product_id = p.product_id
        WHERE c.user_id = ?
      SQL
    )
    erb :cart
  end

  post '/cart/add' do
    redirect '/login' unless session[:user_id]

    product_id = params["product_id"].to_i
    quantity   = (params["quantity"] || 1).to_i

    cart = db.execute("SELECT * FROM carts WHERE user_id = ?", [session[:user_id]]).first
    unless cart
      db.execute("INSERT INTO carts (user_id) VALUES (?)", [session[:user_id]])
      cart = db.execute("SELECT * FROM carts WHERE user_id = ?", [session[:user_id]]).first
    end

    cart_item = db.execute(
      "SELECT * FROM cart_items WHERE cart_id = ? AND product_id = ?",
      [cart["cart_id"], product_id]
    ).first

    if cart_item
      db.execute(
        "UPDATE cart_items SET quantity = quantity + ? WHERE cart_item_id = ?",
        [quantity, cart_item["cart_item_id"]]
      )
    else
      db.execute(
        "INSERT INTO cart_items (cart_id, product_id, quantity) VALUES (?, ?, ?)",
        [cart["cart_id"], product_id, quantity]
      )
    end

    redirect '/cart'
  end


  post '/checkout' do
    redirect '/login' unless session[:user_id]

    cart = db.execute("SELECT * FROM carts WHERE user_id = ?", [session[:user_id]]).first
    cart_items = db.execute(
      "SELECT ci.*, p.price FROM cart_items ci JOIN products p ON ci.product_id = p.product_id WHERE ci.cart_id = ?",
      [cart["cart_id"]]
    )

    total_price = cart_items.sum { |item| item["price"] * item["quantity"] }

    db.execute(
      "INSERT INTO orders (user_id, total_price, status) VALUES (?, ?, 'pending')",
      [session[:user_id], total_price]
    )
    order_id = db.last_insert_row_id

    cart_items.each do |item|
      db.execute(
        "INSERT INTO order_items (order_id, product_id, quantity, price) VALUES (?, ?, ?, ?)",
        [order_id, item["product_id"], item["quantity"], item["price"]]
      )
    end

    db.execute("DELETE FROM cart_items WHERE cart_id = ?", [cart["cart_id"]])

    redirect '/orders'
  end


  get '/orders' do
    redirect '/login' unless session[:user_id]

    @orders = db.execute(
      "SELECT * FROM orders WHERE user_id = ? ORDER BY created_at DESC",
      [session[:user_id]]
    )

    @orders.each do |order|
      order["items"] = db.execute(
        "SELECT oi.*, p.name, p.price FROM order_items oi JOIN products p ON oi.product_id = p.product_id WHERE oi.order_id = ?",
        [order["order_id"]]
      )
    end

    erb :orders
  end

  get '/logout' do
    session.clear
    redirect '/'
  end
end