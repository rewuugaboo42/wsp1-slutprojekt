# Represents an order placed by a user.
# Handles creation of orders from a cart and retrieval of order data.
class Order
  # @return [Integer] unique identifier for the order
  attr_accessor :order_id

  # @return [Integer] ID of the user who placed the order
  attr_accessor :user_id

  # @return [Float, Integer] total price of the order
  attr_accessor :total_price

  # @return [String] current status of the order (e.g. pending, completed)
  attr_accessor :status

  # @return [String, Time] timestamp when the order was created
  attr_accessor :created_at

  # @return [Array<Hash>] list of order items
  attr_accessor :items

  # Initializes a new Order instance.
  #
  # @param attrs [Hash] attributes used to initialize the order
  # @option attrs [Integer] "order_id" the order ID
  # @option attrs [Integer] "user_id" the user ID
  # @option attrs [Float, Integer] "total_price" total price of the order
  # @option attrs [String] "status" order status
  # @option attrs [String, Time] "created_at" creation timestamp
  # @return [Order] a new Order instance
  def initialize(attrs = {})
    @order_id = attrs["order_id"]
    @user_id = attrs["user_id"]
    @total_price = attrs["total_price"]
    @status = attrs["status"]
    @created_at = attrs["created_at"]
  end

  # Creates an order from a shopping cart.
  #
  # This method:
  # - Calculates total price from cart items
  # - Creates an order record
  # - Inserts all order items
  # - Clears the cart
  #
  # @param cart [Cart] the shopping cart
  # @param db [Object] database connection
  # @param user_id [Integer] ID of the user placing the order
  # @return [Order] the newly created order
  def self.create_from_cart(cart, db, user_id)
    cart_items = cart.items(db)
    total_price = cart_items.sum { |item| item["price"] * item["quantity"] }

    db.execute(
      "INSERT INTO orders (user_id, total_price, status)
       VALUES (?, ?, 'pending')",
      [user_id, total_price]
    )

    order_id = db.last_insert_row_id

    cart_items.each do |item|
      db.execute(
        "INSERT INTO order_items (order_id, product_id, quantity, price)
         VALUES (?, ?, ?, ?)",
        [order_id, item["product_id"], item["quantity"], item["price"]]
      )
    end

    cart.clear(db)
    find(order_id, db)
  end

  # Finds a specific order and its items.
  #
  # @param order_id [Integer] the order ID
  # @param db [Object] database connection
  # @return [Order, nil] the order with items or nil if not found
  def self.find(order_id, db)
    row = db.execute("SELECT * FROM orders WHERE order_id = ?", [order_id]).first
    return nil unless row

    order = new(row)
    order.items = db.execute(
      "SELECT oi.*, p.name, p.price
       FROM order_items oi
       JOIN products p ON oi.product_id = p.product_id
       WHERE oi.order_id = ?",
      [order_id]
    )
    order
  end

  # Retrieves all orders for a specific user.
  #
  # @param user_id [Integer] the user ID
  # @param db [Object] database connection
  # @return [Array<Order>] list of user orders
  def self.for_user(user_id, db)
    db.execute(
      "SELECT * FROM orders WHERE user_id = ? ORDER BY created_at DESC",
      [user_id]
    ).map do |row|
      order = new(row)
      order.items = db.execute(
        "SELECT oi.*, p.name, p.price
         FROM order_items oi
         JOIN products p ON oi.product_id = p.product_id
         WHERE oi.order_id = ?",
        [order.order_id]
      )
      order
    end
  end
end