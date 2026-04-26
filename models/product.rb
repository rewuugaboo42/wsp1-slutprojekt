# Represents a product in the webshop.
# Handles product data and database operations.
class Product
  # @return [Integer] unique identifier for the product
  attr_accessor :product_id

  # @return [String] name of the product
  attr_accessor :name

  # @return [String] description of the product
  attr_accessor :description

  # @return [Float, Integer] price of the product
  attr_accessor :price

  # @return [String] image URL for the product
  attr_accessor :image_url

  # Initializes a new Product instance.
  #
  # @param attrs [Hash] attributes used to initialize the product
  # @option attrs [Integer] "product_id" the product ID
  # @option attrs [String] "name" the product name
  # @option attrs [String] "description" the product description
  # @option attrs [Float, Integer] "price" the product price
  # @option attrs [String] "image_url" URL to product image
  # @return [Product] a new Product instance
  def initialize(attrs = {})
    @product_id = attrs["product_id"]
    @name = attrs["name"]
    @description = attrs["description"]
    @price = attrs["price"]
    @image_url = attrs["image_url"]
  end

  # Retrieves all products from the database.
  #
  # @param db [Object] the database connection
  # @return [Array<Product>] list of all products
  def self.all(db)
    db.execute("SELECT * FROM products").map { |row| new(row) }
  end

  # Finds a product by ID.
  #
  # @param id [Integer] the product ID
  # @param db [Object] the database connection
  # @return [Product, nil] the found product or nil if not found
  def self.find(id, db)
    row = db.execute("SELECT * FROM products WHERE product_id = ?", [id]).first
    row ? new(row) : nil
  end

  # Creates and inserts a new product into the database.
  #
  # @param db [Object] the database connection
  # @param params [Hash] product attributes
  # @option params [String] "name" product name
  # @option params [String] "description" product description
  # @option params [String, Numeric] "price" product price
  # @option params [String] "image_url" product image URL
  # @return [void]
  def self.add(db, params)
    db.execute(
      "INSERT INTO products (name, description, price, image_url, stock)
      VALUES (?, ?, ?, ?, ?)",
      [
        params["name"],
        params["description"],
        params["price"],
        params["image_url"],
        0
      ]
    )
  end

  # Updates an existing product in the database.
  #
  # @param id [Integer] the product ID to update
  # @param params [Hash] updated product attributes
  # @option params [String] "name" product name
  # @option params [String] "description" product description
  # @option params [String, Numeric] "price" product price
  # @option params [String] "image_url" product image URL
  # @option params [Integer] "stock" available stock
  # @param db [Object] the database connection
  # @return [void]
  def self.update(id, params, db)
    stock = params["stock"] || 0

    db.execute(
      "UPDATE products
      SET name = ?, description = ?, price = ?, image_url = ?, stock = ?
      WHERE product_id = ?",
      [
        params["name"],
        params["description"],
        params["price"],
        params["image_url"],
        stock,
        id
      ]
    )
  end

  # Deletes a product from the database.
  #
  # @param id [Integer] the product ID to delete
  # @param db [Object] the database connection
  # @return [void]
  def self.delete(id, db)
    db.execute("DELETE FROM products WHERE product_id = ?", [id])
  end
end