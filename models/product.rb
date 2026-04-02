class Product
  attr_accessor :product_id, :name, :description, :price, :image_url

  def initialize(attrs = {})
    @product_id = attrs["product_id"]
    @name = attrs["name"]
    @description = attrs["description"]
    @price = attrs["price"]
    @image_url = attrs["image_url"]
  end

  def self.all(db)
    db.execute("SELECT * FROM products").map { |row| new(row) }
  end

  def self.find(id, db)
    row = db.execute("SELECT * FROM products WHERE product_id = ?", [id]).first
    row ? new(row) : nil
  end

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

  def self.delete(id, db)
    db.execute("DELETE FROM products WHERE product_id = ?", [id])
  end
end