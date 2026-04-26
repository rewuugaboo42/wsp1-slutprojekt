# Represents a shopping cart for a user.
# Handles cart creation, item management, and clearing of cart data.
class Cart
  # @return [Integer] unique identifier for the cart
  attr_accessor :cart_id

  # @return [Integer] ID of the user who owns the cart
  attr_accessor :user_id

  # Initializes a new Cart instance.
  #
  # @param attrs [Hash] attributes used to initialize the cart
  # @option attrs [Integer] "cart_id" the cart ID
  # @option attrs [Integer] "user_id" the user ID
  # @return [Cart] a new Cart instance
  def initialize(attrs = {})
    @cart_id = attrs["cart_id"]
    @user_id = attrs["user_id"]
  end

  # Finds an existing cart or creates a new one for a user.
  #
  # @param user_id [Integer] the user ID
  # @param db [Object] database connection
  # @return [Cart] the found or newly created cart
  def self.find_or_create_by_user(user_id, db)
    cart = db.execute("SELECT * FROM carts WHERE user_id = ?", [user_id]).first

    unless cart
      db.execute("INSERT INTO carts (user_id) VALUES (?)", [user_id])
      cart = db.execute("SELECT * FROM carts WHERE user_id = ?", [user_id]).first
    end

    new(cart)
  end

  # Retrieves all items in the cart.
  #
  # @param db [Object] database connection
  # @return [Array<Hash>] list of cart items with product data
  def items(db)
    db.execute(
      <<~SQL, [cart_id]
        SELECT ci.cart_item_id, ci.quantity, p.product_id, p.name, p.price, p.image_url
        FROM cart_items ci
        JOIN products p ON ci.product_id = p.product_id
        WHERE ci.cart_id = ?
      SQL
    )
  end

  # Adds a product to the cart or increases quantity if it already exists.
  #
  # @param product_id [Integer] the product ID
  # @param quantity [Integer] amount to add
  # @param db [Object] database connection
  # @return [void]
  def add_item(product_id, quantity, db)
    cart_item = db.execute(
      "SELECT * FROM cart_items WHERE cart_id = ? AND product_id = ?",
      [cart_id, product_id]
    ).first

    if cart_item
      db.execute(
        "UPDATE cart_items SET quantity = quantity + ? WHERE cart_item_id = ?",
        [quantity, cart_item["cart_item_id"]]
      )
    else
      db.execute(
        "INSERT INTO cart_items (cart_id, product_id, quantity)
         VALUES (?, ?, ?)",
        [cart_id, product_id, quantity]
      )
    end
  end

  # Removes a product from the cart.
  #
  # @param product_id [Integer] the product ID to remove
  # @param db [Object] database connection
  # @return [void]
  def remove_item(product_id, db)
    db.execute(
      "DELETE FROM cart_items WHERE cart_id = ? AND product_id = ?",
      [cart_id, product_id]
    )
  end

  # Clears all items from the cart.
  #
  # @param db [Object] database connection
  # @return [void]
  def clear(db)
    db.execute("DELETE FROM cart_items WHERE cart_id = ?", [cart_id])
  end
end