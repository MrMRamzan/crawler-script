require 'sqlite3'
require 'byebug'

class Product

  def self.connection
    db = SQLite3::Database.open("database/finology.db")
    r = yield db
    db.close
    return r
  end

  def self.exists?(name)
    result = self.connection do |db|
      db.execute("select count() from products where name = ?", [name])
    end
    return result[0][0] > 0
  end

  def self.create(product)
    result = self.connection do |db|
      db.execute("INSERT INTO products(name, price, description, extra_information) VALUES(?, ?, ?, ?)", [product[:Name], product[:Price], product[:Description], product[:ExtraInformation] ])
    end
  end 
end

# For sqlite3 console
# .open database/finology.db
# .tables (opt)
# SELECT * FROM products;
# DELETE FROM products;
# SELECT COUNT(*) FROM products;