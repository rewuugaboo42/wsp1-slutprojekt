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
end