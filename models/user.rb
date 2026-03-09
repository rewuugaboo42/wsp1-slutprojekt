require 'bcrypt'

class User
  attr_accessor :user_id, :username, :email, :password_hash

  def initialize(attrs = {})
    @user_id = attrs["user_id"]
    @username = attrs["username"]
    @email = attrs["email"]
    @password_hash = attrs["password_hash"]
  end

  def self.find_by_email(email, db)
    row = db.execute("SELECT * FROM users WHERE email = ?", [email]).first
    row ? new(row) : nil
  end

  def self.find_by_username_or_email(username, email, db)
    row = db.execute("SELECT * FROM users WHERE username = ? OR email = ?", [username, email]).first
    row ? new(row) : nil
  end

  def self.create(username, email, password, db)
    password_hash = BCrypt::Password.create(password)
    db.execute("INSERT INTO users (username, email, password_hash) VALUES (?, ?, ?)", [username, email, password_hash])
    find_by_email(email, db)
  end

  def authenticate(password)
    BCrypt::Password.new(password_hash) == password
  end
end