class Cart
  attr_accessor :cart_id, :user_id

  def initialize(attrs = {})
    @cart_id = attrs["cart_id"]
    @user_id = attrs["user_id"]
  end

  def self.find_or_create_by_user(user_id, db)
    cart = db.execute("SELECT * FROM carts WHERE user_id = ?", [user_id]).first
    unless cart
      db.execute("INSERT INTO carts (user_id) VALUES (?)", [user_id])
      cart = db.execute("SELECT * FROM carts WHERE user_id = ?", [user_id]).first
    end
    new(cart)
  end

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

  def add_item(product_id, quantity, db)
    cart_item = db.execute("SELECT * FROM cart_items WHERE cart_id = ? AND product_id = ?", [cart_id, product_id]).first
    if cart_item
      db.execute("UPDATE cart_items SET quantity = quantity + ? WHERE cart_item_id = ?", [quantity, cart_item["cart_item_id"]])
    else
      db.execute("INSERT INTO cart_items (cart_id, product_id, quantity) VALUES (?, ?, ?)", [cart_id, product_id, quantity])
    end
  end

  def clear(db)
    db.execute("DELETE FROM cart_items WHERE cart_id = ?", [cart_id])
  end
end