-- DROP TABLE commands:
DROP TABLE IF EXISTS reviews; 
DROP TABLE IF EXISTS purchases;
DROP TABLE IF EXISTS employee_log;
DROP TABLE IF EXISTS requests;
DROP TABLE IF EXISTS lego_parts; 
DROP TABLE IF EXISTS lego_sets; 
DROP TABLE IF EXISTS themes;
DROP TABLE IF EXISTS categories; 
DROP TABLE IF EXISTS product_inventory;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS discounts;
DROP TABLE IF EXISTS employees;

-- CREATE TABLE commands:

-- Themes for the lego sets.
CREATE TABLE themes (
  -- Unique ID for each theme.
  theme_id INT PRIMARY KEY,

  -- Name of the theme.
  theme_name VARCHAR(70) NOT NULL,

  -- Larger theme (can be NULL).
  parent_id INT
);


-- Categories for the lego parts.
CREATE TABLE categories (
  -- Unique ID for each category.
  category_id INT PRIMARY KEY,

  -- Name of the category.
  category_name VARCHAR(100) NOT NULL
);


CREATE TABLE product_inventory (
  -- Unique ID for each product.
  product_id INT PRIMARY KEY,

  -- Price for each product.
  product_price NUMERIC(6, 2) NOT NULL,

  -- Name of each product.
  product_name VARCHAR(255) NOT NULL,

  -- Quantity of the product inventory.
  quantity INT NOT NULL
);


-- All lego set information.
CREATE TABLE lego_sets (
  -- Unique ID for each product.
  product_id INT PRIMARY KEY,

  -- Number of parts in the set.
  num_parts INT NOT NULL,

  -- Estimated time, in minutes,
  -- to complete the set.
  time_to_complete INT NOT NULL, 

  -- Year the set was released.
  year_released YEAR NOT NULL, 

  -- Theme of the set.
  theme_id INT,

  -- Specialization of product.
  -- No cascade on UPDATE because product IDs don't change often.
  FOREIGN KEY (product_id) REFERENCES product_inventory(product_id)
      ON DELETE CASCADE,
  FOREIGN KEY (theme_id) REFERENCES themes(theme_id)
      ON DELETE CASCADE
);


-- All lego parts information.
CREATE TABLE lego_parts (
  -- Unique ID for each product.
  product_id INT PRIMARY KEY,

  -- Category of the part.
  category_id INT, 

  -- Specialization of product.
  FOREIGN KEY (product_id) REFERENCES product_inventory(product_id)
      ON DELETE CASCADE,
  FOREIGN KEY (category_id) REFERENCES categories(category_id)
      ON DELETE CASCADE
);

-- Discounts based on membership level.
CREATE TABLE discounts (
  -- Type of member.
  -- VIP : 'V', Regular: 'R'
  member_type CHAR(1) PRIMARY KEY,

  -- Discount amount.
  -- 10 represents 10% etc.
  discount_amount INT NOT NULL,
  
  CHECK(member_type IN ('V', 'R')),
  CHECK(discount_amount >=0 AND discount_amount <= 100)
);


-- Registered customers.
CREATE TABLE customers (
  -- Unique username for each customer.
  customer_username VARCHAR(50) PRIMARY KEY,

  -- Customer first and last name.
  customer_name VARCHAR(100) NOT NULL,

  -- Customer email.
  customer_email VARCHAR(50) NOT NULL,

  -- Type of member.
  -- VIP : 'V', Regular: 'R'
  member_type CHAR(1),

  FOREIGN KEY (member_type) REFERENCES discounts(member_type)
    ON UPDATE CASCADE
    ON DELETE CASCADE
);


-- Purchases made by customers.
-- Each purchase is only ONE item.
CREATE TABLE purchases (
  -- Unique ID for each purchase.
  purchase_id SERIAL PRIMARY KEY,

  -- Product that was purchased.
  product_id INT,

  -- Customer that made the purchase.
  customer_username VARCHAR(50),

  -- Purchased item total.
  -- Because customers often get discounts,
  -- this keeps track of historical purchase totals in case
  -- discount amounts change.
  purchase_item_total NUMERIC(6, 2) NOT NULL,

  -- Time of purchase.
  purchase_time TIMESTAMP NOT NULL,

  FOREIGN KEY (product_id) REFERENCES product_inventory(product_id)
    ON DELETE CASCADE,

  FOREIGN KEY (customer_username) REFERENCES customers(customer_username)
    ON DELETE CASCADE
);


-- Reviews made for purchases.
-- Weak entity.
CREATE TABLE reviews (
  -- Review is uniquely identified by a purchase ID.
  -- Chose not to merge the two tables.
  -- Not using SERIAL again because we're not auto-incrementing this.
  purchase_id BIGINT UNSIGNED PRIMARY KEY,

  -- Customer that made the review.
  customer_username VARCHAR(50),

  -- Time of review.
  review_time TIMESTAMP NOT NULL, 

  -- Rating given on a scale from 1-5.
  rating INT NOT NULL,

  -- Short review box.
  -- Can be NULL.
  review VARCHAR(500),

  -- Review is only for a given purchase.
  FOREIGN KEY (purchase_id) REFERENCES purchases(purchase_id)
    ON DELETE CASCADE,

  -- Included so that we can retrieve customer name.
  FOREIGN KEY (customer_username) REFERENCES customers(customer_username)
    ON UPDATE CASCADE
    ON DELETE CASCADE,

  -- Restrict the range of ratings to 1-5.
  CHECK (rating <= 5 AND rating >= 1)
);


-- Request made for ONE product.
-- Possible idea: Check that each product requested has 0 inventory.
CREATE TABLE requests (
  -- Unique ID for each request.
  request_id SERIAL PRIMARY KEY,

  -- Product that request was made for.
  product_id INT,

  -- Customer that made the purchase.
  customer_username VARCHAR(50),

  -- Status of the request.
  -- Fulfilled: 'F', In Progress: 'P', Unfulfilled: 'U'
  request_status CHAR(1) NOT NULL,

  FOREIGN KEY (product_id) REFERENCES product_inventory(product_id)
    ON DELETE CASCADE,
  FOREIGN KEY (customer_username) REFERENCES customers(customer_username)
    ON UPDATE CASCADE
    ON DELETE CASCADE,

  -- Check that the status is valid.
  CHECK(request_status IN ('F', 'P', 'U'))
);

-- Employees that can manage the database and fulfill requests.
CREATE TABLE employees (
  -- Unique username for each employee.
  employee_username VARCHAR(50) PRIMARY KEY,

  -- Employee Name.
  employee_name VARCHAR(100) NOT NULL,

  -- Permissions.
  -- Requests read: 'R', write: 'W', readwrite: 'RW'
  employee_permissions VARCHAR(2) NOT NULL,

  CHECK ((employee_permissions) IN ('R', 'W', 'RW'))
);

-- Employee log of requests that are fulfilled.
CREATE TABLE employee_log (
  -- Request that was fulfilled.
  request_id BIGINT UNSIGNED,

  -- Employee that made the change.
  employee_username VARCHAR(50),

  -- Time of change.
  log_time TIMESTAMP NOT NULL,

  -- Brief description of change that was made.
  change_made VARCHAR(255) NOT NULL,

  PRIMARY KEY (request_id, employee_username),

  FOREIGN KEY (request_id) REFERENCES requests(request_id)
    ON DELETE CASCADE,

  FOREIGN KEY (employee_username) REFERENCES employees(employee_username)
    ON UPDATE CASCADE
    ON DELETE CASCADE
);

CREATE INDEX idx_theme_name ON themes(theme_name);
CREATE INDEX idx_prod_price ON product_inventory(product_price);