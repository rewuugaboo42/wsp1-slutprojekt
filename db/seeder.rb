require 'sqlite3'

class Seeder

  def self.seed!
    puts "Using db file: #{DB_PATH}"
    puts "🧹 Dropping old tables..."
    drop_tables
    puts "🧱 Creating tables..."
    create_tables
    puts "🍎 Populating tables..."
    populate_tables
    puts "✅ Done seeding the database!"
  end

  def self.drop_tables
    db.execute('DROP TABLE IF EXISTS users')
    db.execute('DROP TABLE IF EXISTS categories')
    db.execute('DROP TABLE IF EXISTS products')
    db.execute('DROP TABLE IF EXISTS carts')
    db.execute('DROP TABLE IF EXISTS cart_items')
    db.execute('DROP TABLE IF EXISTS orders')
    db.execute('DROP TABLE IF EXISTS order_items')
  end

  def self.create_tables
    db.execute <<~SQL
      CREATE TABLE users (
        user_id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        email TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      );
    SQL

    db.execute <<~SQL
      CREATE TABLE categories (
        category_id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      );
    SQL

    db.execute <<~SQL
      CREATE TABLE products (
        product_id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        price REAL NOT NULL,
        stock INTEGER NOT NULL,
        category_id INTEGER,
        image_url TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (category_id) REFERENCES categories(category_id)
      );
    SQL

    db.execute <<~SQL
      CREATE TABLE carts (
        cart_id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER UNIQUE,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(user_id)
      );
    SQL

    db.execute <<~SQL
      CREATE TABLE cart_items (
        cart_item_id INTEGER PRIMARY KEY AUTOINCREMENT,
        cart_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (cart_id) REFERENCES carts(cart_id),
        FOREIGN KEY (product_id) REFERENCES products(product_id),
        UNIQUE (cart_id, product_id)
      );
    SQL

    db.execute <<~SQL
      CREATE TABLE orders (
        order_id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        total_price REAL NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(user_id)
      );
    SQL

    db.execute <<~SQL
      CREATE TABLE order_items (
        order_item_id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
        price REAL NOT NULL,
        FOREIGN KEY (order_id) REFERENCES orders(order_id),
        FOREIGN KEY (product_id) REFERENCES products(product_id)
      );
    SQL
  end

  def self.populate_tables
    db.execute <<~SQL
      INSERT INTO users (username, email, password_hash)
      VALUES
      ('Albert Westman', 'albert.pj.westman@gmail.com', 'hashed_password_here'),
      ('Emma Svensson', 'emma@example.com', 'another_hash_here');
    SQL

    db.execute <<~SQL
      INSERT INTO categories (name)
      VALUES
      ('Kött'),
      ('Fisk'),
      ('Vegetariskt');
    SQL

    db.execute <<~SQL
      INSERT INTO products (name, description, price, stock, category_id, image_url)
      VALUES
      ('Högrev', 'Gött kött till hamburgare.', 67.0, 15, 1, 'urlhogrev.com'),
      ('Laxfilé', 'Färsk norsk lax.', 129.0, 10, 2, 'urllax.com'),
      ('Vegobiff', 'Saftig vegetarisk biff.', 45.0, 20, 3, 'urlvegobiff.com');
    SQL

    db.execute <<~SQL
      INSERT INTO carts (user_id)
      VALUES
      (1),
      (2);
    SQL

    db.execute <<~SQL
      INSERT INTO cart_items (cart_id, product_id, quantity)
      VALUES
      (1, 1, 2),
      (1, 3, 1),
      (2, 2, 1);
    SQL

    db.execute <<~SQL
      INSERT INTO orders (user_id, total_price, status)
      VALUES
      (1, 179.0, 'paid'),
      (2, 129.0, 'pending');
    SQL

    db.execute <<~SQL
      INSERT INTO order_items (order_id, product_id, quantity, price)
      VALUES
      (1, 1, 2, 67.0),
      (1, 3, 1, 45.0),
      (2, 2, 1, 129.0);
    SQL
  end

  private

  def self.db
    @db ||= begin
      db = SQLite3::Database.new(DB_PATH)
      db.results_as_hash = true
      db
    end
  end
end

Seeder.seed!
