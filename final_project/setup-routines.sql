/* --------------------- INDEX OF PROCEDURES ---------------------

  ---------------- CUSTOMERS ----------------------
  1. SEARCH FOR SETS
      - get_sets_max_price
      - get_sets_in_theme
      - get_price_and_rating
  2. PURCHASE
      - make_purchase
  3. MAKE REQUEST
      - request_additional_inventory
  4. WRITE REVIEW
      - write_review

  ---------------- EMPLOYEES ----------------------
  1. FULFILL REQUEST
      - fulfill_request (automatically updates log)
  2. VIEW REVENUE
      - show_total_revenue
      
*/

-- --------------------- DROP FUNCTION STATEMENTS ---------------------

-- SECTION 1: CUSTOMER QUERIES
DROP FUNCTION IF EXISTS find_theme_id;
DROP FUNCTION IF EXISTS find_product_name;

DROP PROCEDURE IF EXISTS get_sets_in_theme;
DROP PROCEDURE IF EXISTS get_sets_max_price;
DROP PROCEDURE IF EXISTS get_price_and_rating;

-- SECTION 2: CUSTOMER ACTIONS
DROP FUNCTION IF EXISTS find_retail_price;
DROP FUNCTION IF EXISTS find_customer_discount;
DROP FUNCTION IF EXISTS find_customer_username_purchase;

DROP PROCEDURE IF EXISTS make_purchase;
DROP PROCEDURE IF EXISTS update_inventory_purchase;
DROP PROCEDURE IF EXISTS request_additional_inventory;
DROP PROCEDURE IF EXISTS write_review;

DROP TRIGGER IF EXISTS trg_purchase_update_inventory;

-- SECTION 3: EMPLOYEE ACTIONS
DROP FUNCTION IF EXISTS find_product_id_request;

DROP PROCEDURE IF EXISTS update_employee_log;
DROP PROCEDURE IF EXISTS fulfill_request;
DROP PROCEDURE IF EXISTS show_total_revenue;

DROP TRIGGER IF EXISTS trg_fulfill_request;


-- --------------------- SECTION 1: CUSTOMER QUERIES ---------------------

-- HELPER FUNCTION: Finds the theme ID of a given theme name.
DELIMITER !
CREATE FUNCTION find_theme_id(theme_name VARCHAR(70)) RETURNS INT DETERMINISTIC
BEGIN
  DECLARE matching_theme_id INT;
  
  SELECT theme_id INTO matching_theme_id
  FROM themes WHERE theme_name=themes.theme_name
  ORDER BY theme_id 
  LIMIT 1;
  
  RETURN matching_theme_id;
END !
DELIMITER ;


-- HELPER FUNCTION: Finds the product name given a product ID.
DELIMITER !
CREATE FUNCTION find_product_name(product_id INT) RETURNS VARCHAR(255) DETERMINISTIC 
BEGIN 
  DECLARE desired_product_name VARCHAR(255);

  SELECT product_name INTO desired_product_name
  FROM product_inventory WHERE product_id=product_inventory.product_id;

  RETURN product_name;
END !
DELIMITER ;


-- Returns all sets under a given price point.
DELIMITER !
CREATE PROCEDURE get_sets_max_price(
  IN max_price NUMERIC(6,2)
)
BEGIN
  SELECT product_id, product_name, product_price FROM product_inventory
  WHERE product_inventory.product_price<=max_price;
END !
DELIMITER ;


-- Returns the name, product name, and price of all sets with a given theme name.
DELIMITER !
CREATE PROCEDURE get_sets_in_theme(
  IN theme_name VARCHAR(70)
)
BEGIN
  DECLARE desired_theme_id INT;
  SET desired_theme_id=find_theme_id(theme_name);

  SELECT product_id, product_name, product_price
  FROM lego_sets NATURAL JOIN product_inventory 
  WHERE desired_theme_id=lego_sets.theme_id
  ORDER BY product_id;
END !
DELIMITER ;


-- Returns the price and average rating of a set.
-- If no ratings available, then default to 0.
DELIMITER !
CREATE PROCEDURE get_price_and_rating(
  IN product_id INT,
  OUT desired_price NUMERIC(6,2), 
  OUT desired_avg_rating FLOAT
)
BEGIN
  SELECT product_price 
  INTO desired_price
  FROM product_inventory 
  WHERE product_id=product_inventory.product_id;

  SELECT IFNULL(AVG(rating), 0) AS avg_rating 
  INTO desired_avg_rating
  FROM reviews NATURAL LEFT JOIN purchases 
  WHERE product_id=purchases.product_id;
END !
DELIMITER ;


-- --------------------- SECTION 2: CUSTOMER ACTIONS ---------------------

-- -------------- ACTION 1: MAKE A PURCHASE ----------------------
-- Find price of item.
DELIMITER !
CREATE FUNCTION find_retail_price(product_id INT) RETURNS NUMERIC(6,2) DETERMINISTIC
BEGIN
  DECLARE price NUMERIC(6,2);

  SELECT product_price INTO price
  FROM product_inventory 
  WHERE product_id=product_inventory.product_id;

  RETURN price;
END !
DELIMITER ;


-- Find discount that customer receives.
DELIMITER !
CREATE FUNCTION find_customer_discount(cust_username VARCHAR(50)) RETURNS INT DETERMINISTIC
BEGIN 
  DECLARE memb_type CHAR(1); 
  
  SELECT member_type INTO memb_type 
  FROM customers
  WHERE cust_username=customers.customer_username;

  IF memb_type = 'V'
   THEN RETURN 30;
  ELSE RETURN 0;
  END IF;
END !
DELIMITER ;


-- Update inventory quantity to reflect one purchase.
DELIMITER !
CREATE PROCEDURE update_inventory_purchase(
  IN product_id INT
)
BEGIN 
  UPDATE product_inventory 
  SET quantity=quantity - 1
  WHERE product_id=product_inventory.product_id;
END !
DELIMITER ;


-- Trigger to handle purchases.
DELIMITER !
CREATE TRIGGER trg_purchase_update_inventory
  AFTER INSERT ON purchases FOR EACH ROW
BEGIN
  CALL update_inventory_purchase(NEW.product_id);
END !
DELIMITER ;


-- Make a purchase and update the purchases relation.
DELIMITER !
CREATE PROCEDURE make_purchase(
  IN product_id INT,
  IN customer_username VARCHAR(50)
)
BEGIN
  DECLARE retail_price NUMERIC(6,2);
  DECLARE customer_discount INT;

  SET retail_price=find_retail_price(product_id);
  SET customer_discount=find_customer_discount(customer_username);

  INSERT INTO purchases 
    VALUES (DEFAULT, product_id, customer_username, retail_price*(1-0.01*customer_discount), NOW());
END !
DELIMITER ;


-- -------------- ACTION 2: MAKE A REQUEST ----------------------

-- Create a request for additional inventory of product.
DELIMITER !
CREATE PROCEDURE request_additional_inventory(
  IN product_id INT,
  IN customer_username VARCHAR(50)
)
BEGIN 
  INSERT INTO requests
    VALUES (DEFAULT, product_id, customer_username, 'U');
END !
DELIMITER ;


-- -------------- ACTION 3: WRITE A REVIEW ----------------------
DELIMITER !
CREATE FUNCTION find_customer_username_purchase(purchase_id BIGINT UNSIGNED
) RETURNS VARCHAR(50) DETERMINISTIC
BEGIN 
  DECLARE cust_username VARCHAR(50); 
  
  SELECT customer_username INTO cust_username
  FROM purchases WHERE purchase_id=purchases.purchase_id;

  RETURN cust_username;
END !
DELIMITER ;


DELIMITER !
CREATE PROCEDURE write_review(
  IN purchase_id BIGINT UNSIGNED,
  IN rating INT, 
  IN review VARCHAR(500)
)
BEGIN 
  DECLARE matching_customer_username VARCHAR(50);
  SET matching_customer_username=find_customer_username_purchase(purchase_id);

  INSERT INTO reviews
    VALUES (purchase_id, matching_customer_username, NOW(), rating, review);
END !
DELIMITER ;


-- --------------------- SECTION 3: EMPLOYEE ACTIONS ---------------------

-- -------------- ACTION 1: FULFILL A REQUEST ----------------------
-- Update log when employee fulflls a request.
DELIMITER !
CREATE PROCEDURE update_employee_log(
  IN request_id BIGINT UNSIGNED 
)
BEGIN 
 -- Updates the employee log.
  DECLARE curr_employee_username VARCHAR(50);

  -- TODO: Set to actual current employee.
  SET curr_employee_username='emin';

  INSERT INTO employee_log
    VALUES (request_id, curr_employee_username, NOW(), 'Fulfilled request.');
END !
DELIMITER ;


-- Trigger to execute when 'request' updates (i.e. a request is fulfilled).
DELIMITER !
CREATE TRIGGER trg_fulfill_request
  AFTER UPDATE ON requests FOR EACH ROW 
BEGIN 
  CALL update_employee_log(NEW.request_id);
END !
DELIMITER ;


-- Find matching product ID given a request ID.
DELIMITER !
CREATE FUNCTION find_product_id_request(request_id BIGINT UNSIGNED) RETURNS INT DETERMINISTIC
BEGIN
  DECLARE matching_product_id INT;

  SELECT requests.product_id INTO matching_product_id 
  FROM requests WHERE request_id=requests.request_id;

  RETURN matching_product_id;
END !
DELIMITER ;


-- Fulfill request by increasing product inventory and updating status.
DELIMITER !
CREATE PROCEDURE fulfill_request(
  IN request_id BIGINT UNSIGNED
)
BEGIN 
  -- Find product ID for the request.
  DECLARE requested_product_id INT;
  SET requested_product_id=find_product_id_request(request_id);

  -- Increases inventory.
  UPDATE product_inventory 
  SET quantity=quantity+1
  WHERE requested_product_id=product_inventory.product_id;

  -- Updates status of request in requests.
  UPDATE requests
  SET request_status='F'
  WHERE request_id=requests.request_id;
END !
DELIMITER ;


-- -------------- ACTION 2: VIEW REVENUE ----------------------
-- Displays total revenue.
DELIMITER !
CREATE PROCEDURE show_total_revenue(
  OUT total_revenue NUMERIC(6,2)
)
BEGIN 
  SELECT SUM(purchase_item_total) 
  FROM purchases
  INTO total_revenue;
END !
DELIMITER ;