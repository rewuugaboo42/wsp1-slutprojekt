require 'debug'
require "awesome_print"
require 'bcrypt'
require_relative 'models/user'
require_relative 'models/cart'
require_relative 'models/order'
require_relative 'models/product'

# Sinatra application handling routing, authentication,
# product management, cart operations, and orders.
class App < Sinatra::Base
  # Enables session support for user authentication
  enable :sessions

  # Configures cookie-based session storage
  use Rack::Session::Cookie, 
    key: 'rack.session',
    path: '/',
    secret: "cf22c9d6061b3e067155e59d775d4406c92b6afc4aaff0a4131e9165eb2d492b597ace501a3df36043ecba99ae29474acac0cbd8c75fb5f46503b3e90d8b8159"

  # Enables development debugging features
  setup_development_features(self)

  # Returns a cached SQLite database connection
  #
  # @return [SQLite3::Database] database connection
  def db
    return @db if @db
    @db = SQLite3::Database.new(DB_PATH)
    @db.results_as_hash = true

    return @db
  end

  # Stores failed login attempts per IP address
  FAILED_LOGINS = {}

  # Maximum allowed login attempts before cooldown
  MAX_ATTEMPTS = 5

  # Cooldown time in seconds after too many failed attempts
  COOLDOWN = 600

  # Retrieves client IP address
  #
  # @return [String] IP address of current request
  def client_ip
    request.ip
  end
  
  # Checks if an IP address is currently blocked due to failed login attempts
  #
  # @param ip [String] client IP address
  # @return [Boolean] true if blocked, false otherwise
  def blocked?(ip)
    data = FAILED_LOGINS[ip]
    return false unless data

    if data[:count] >= MAX_ATTEMPTS
      if Time.now - data[:last_attempt] < COOLDOWN
        return true
      else
        FAILED_LOGINS.delete(ip)
      end
    end

    false
  end

  # Registers a failed login attempt for an IP address
  #
  # @param ip [String] client IP address
  # @return [void]
  def register_failed_attempt(ip)
    FAILED_LOGINS[ip] ||= { count: 0, last_attempt: Time.now }
    FAILED_LOGINS[ip][:count] += 1
    FAILED_LOGINS[ip][:last_attempt] = Time.now
  end

  # Resets failed login attempts for an IP address
  #
  # @param ip [String] client IP address
  # @return [void]
  def reset_attempts(ip)
    FAILED_LOGINS.delete(ip)
  end

  # Displays all products on the products page
  get '/products' do
    @products = Product.all(db)
    user = nil

    # Load current user from session if logged in
    if session[:user_id]
      row = db.execute("SELECT * FROM users WHERE user_id = ?", [session[:user_id]]).first
      user = User.new(row) if row
    end

    # Check if user has admin privileges
    if user && user.admin?
      @admin = true
    else
      @admin = false
    end

    erb (:"product/index")
  end

  # Renders login page
  get '/login' do
    erb (:"user/login")
  end

  # Handles user login authentication
  post '/login' do
    ip = client_ip

    if blocked?(ip)
      @error = "Too many attempts. Try again later."
      return erb(:"user/login")
    end

    login_email = params["email"]
    login_password = params["password"]

    user = User.find_by_email(login_email, db)

    if user && BCrypt::Password.new(user.password_hash) == login_password
      session[:user_id] = user.user_id

      reset_attempts(ip)

      puts "Login success #{login_email} from #{ip}"

      redirect '/products'
    else
      register_failed_attempt(ip)

      puts "Login failed #{login_email} from #{ip}"

      @error = "Wrong email or password"
      erb(:"user/login")
    end
  end

  # Renders signup page
  get '/signup' do
    erb (:"user/signup")
  end

  # Handles user registration
  post '/signup' do
    signup_username = params["username"]
    signup_email = params["email"]
    signup_password = params["password"]

    user = User.find_by_username_or_email(signup_username, signup_email, db)

    if user
      @error = "Username or email already exists"
      return erb (:"user/signup")
    else
      User.create(signup_username, signup_email, signup_password, db)
      redirect '/login'
    end
  end

  # Displays user's shopping cart
  get '/cart' do
    redirect '/login' unless session[:user_id]

    cart = Cart.find_or_create_by_user(session[:user_id], db)
    @cart_items = cart.items(db)

    erb (:"cart/cart")
  end

  # Adds product to cart
  post '/cart/add' do
    redirect '/login' unless session[:user_id]

    product_id = params["product_id"].to_i
    quantity   = (params["quantity"] || 1).to_i

    cart = Cart.find_or_create_by_user(session[:user_id], db)
    cart.add_item(product_id, quantity, db)

    redirect '/cart'
  end

  # Removes product from cart
  post '/cart/delete' do
    redirect '/login' unless session[:user_id]

    product_id = params["product_id"].to_i

    cart = Cart.find_or_create_by_user(session[:user_id], db)
    cart.remove_item(product_id, db)

    redirect '/cart'
  end

  # Renders new product form
  get '/products/new' do
    redirect '/login' unless session[:user_id]
    erb (:"product/new")
  end

  # Creates a new product
  post '/products' do
    redirect '/login' unless session[:user_id]

    Product.add(db, params)

    redirect '/products'
  end

  # Renders product edit page
  get '/products/:id/edit' do
    redirect '/login' unless session[:user_id]

    @product = Product.find(params[:id], db)
    halt 404, "Product not found" unless @product

    erb (:"product/edit")
  end

  # Updates a product
  post '/products/:id/update' do
    redirect '/login' unless session[:user_id]

    Product.update(params[:id], params, db)

    redirect '/products'
  end

  # Deletes a product
  post '/products/:id/delete' do
    redirect '/login' unless session[:user_id]

    Product.delete(params[:id], db)

    redirect '/products'
  end

  # Creates order from cart (checkout)
  post '/checkout' do
    redirect '/login' unless session[:user_id]

    cart = Cart.find_or_create_by_user(session[:user_id], db)
    Order.create_from_cart(cart, db, session[:user_id])

    redirect '/orders'
  end

  # Displays user orders
  get '/orders' do
    redirect '/login' unless session[:user_id]

    @orders = Order.for_user(session[:user_id], db)

    erb (:"checkout/orders")
  end

  # Admin dashboard page
  get '/admin' do
    user = nil

    if session[:user_id]
      row = db.execute("SELECT * FROM users WHERE user_id = ?", [session[:user_id]]).first
      user = User.new(row) if row
    end

    redirect '/' unless user && user.admin?

    erb (:"admin/admin")
  end

  # Logs out the current user
  get '/logout' do
    session.clear
    redirect '/'
  end
end