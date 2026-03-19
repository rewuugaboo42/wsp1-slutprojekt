require 'bcrypt'

# Represents a user in the system.
# Responsible for handling user data and authentication logic.
class User
  # @return [Integer] unique identifier for the user
  attr_accessor :user_id

  # @return [String] username of the user
  attr_accessor :username

  # @return [String] email address of the user
  attr_accessor :email

  # @return [String] hashed password for secure storage
  attr_accessor :password_hash

  # @return [String] permission role of the user
  attr_accessor :role

  # Initializes a new User instance.
  #
  # @param attrs [Hash] attributes used to initialize the user
  # @option attrs [Integer] "user_id" the user's ID
  # @option attrs [String] "username" the username
  # @option attrs [String] "email" the email address
  # @option attrs [String] "password_hash" the hashed password
  # @return [User] a new instance of User
  def initialize(attrs = {})
    @user_id = attrs["user_id"]
    @username = attrs["username"]
    @email = attrs["email"]
    @password_hash = attrs["password_hash"]
    @role = attrs["role"]
  end

  def admin?
    role == "admin"
  end

  # Finds a user by email.
  #
  # @param email [String] the email to search for
  # @param db [Object] the database connection
  # @return [User, nil] the found user or nil if not found
  def self.find_by_email(email, db)
    row = db.execute("SELECT * FROM users WHERE email = ?", [email]).first
    row ? new(row) : nil
  end

  # Finds a user by username or email.
  #
  # @param username [String] the username to search for
  # @param email [String] the email to search for
  # @param db [Object] the database connection
  # @return [User, nil] the found user or nil if not found
  def self.find_by_username_or_email(username, email, db)
    row = db.execute("SELECT * FROM users WHERE username = ? OR email = ?", [username, email]).first
    row ? new(row) : nil
  end

  # Creates a new user and saves it to the database.
  #
  # @param username [String] the desired username
  # @param email [String] the user's email
  # @param password [String] the plaintext password
  # @param db [Object] the database connection
  # @return [User] the newly created user
  def self.create(username, email, password, db, role = "user")
    password_hash = BCrypt::Password.create(password)
    db.execute(
      "INSERT INTO users (username, email, password_hash, role) VALUES (?, ?, ?, ?)",
      [username, email, password_hash, role]
    )
    find_by_email(email, db)
  end

  # Authenticates a user by comparing a plaintext password
  # with the stored password hash.
  #
  # @param password [String] the plaintext password to verify
  # @return [Boolean] true if authentication succeeds, false otherwise
  def authenticate(password)
    BCrypt::Password.new(password_hash) == password
  end
end