class Order
  attr_accessor :order_id, :user_id, :total_price, :status, :created_at

  def initialize(attrs = {})
    @order_id = attrs["order_id"]
    @user_id = attrs["user_id"]
    @total_price = attrs["total_price"]
    @status = attrs["status"]
    @created_at = attrs["created_at"]
  end

  def self.create_from_cart(cart, db, user_id)
    cart_items = cart.items(db)
    total_price = cart_items.sum { |item| item["price"] * item["quantity"] }

    db.execute("INSERT INTO orders (user_id, total_price, status) VALUES (?, ?, 'pending')", [user_id, total_price])
    order_id = db.last_insert_row_id

    cart_items.each do |item|
      db.execute("INSERT INTO order_items (order_id, product_id, quantity, price) VALUES (?, ?, ?, ?)", [order_id, item["product_id"], item["quantity"], item["price"]])
    end

    cart.clear(db)
    find(order_id, db)
  end

  def self.find(order_id, db)
    row = db.execute("SELECT * FROM orders WHERE order_id = ?", [order_id]).first
    return nil unless row

    order = new(row)
    order.items = db.execute("SELECT oi.*, p.name, p.price FROM order_items oi JOIN products p ON oi.product_id = p.product_id WHERE oi.order_id = ?", [order_id])
    order
  end

  def self.for_user(user_id, db)
    db.execute("SELECT * FROM orders WHERE user_id = ? ORDER BY created_at DESC", [user_id]).map do |row|
      order = new(row)
      order.items = db.execute("SELECT oi.*, p.name, p.price FROM order_items oi JOIN products p ON oi.product_id = p.product_id WHERE oi.order_id = ?", [order.order_id])
      order
    end
  end

  attr_accessor :items
end