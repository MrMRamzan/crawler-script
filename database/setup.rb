require 'sqlite3'

db = SQLite3::Database.new "finology.db"

# Create a table
db.execute <<-SQL
  create table products (
    name varchar(50),
    price REAL,
    description varchar(50),
    extra_information text
  );
SQL