-- Computes the number of sets in each given theme.
SELECT theme_name, 
       COUNT(DISTINCT product_id) AS num_sets 
       FROM themes NATURAL JOIN lego_sets
GROUP BY theme_name
ORDER BY theme_name;

-- Computes the average rating for products that have received reviews.
SELECT product_name, AVG(rating) AS avg_rating 
  FROM reviews NATURAL LEFT JOIN 
  purchases JOIN 
  product_inventory ON (purchases.product_id=product_inventory.product_id)
GROUP BY product_name;

-- Lists each customer and amount of money they have spent.
SELECT customer_name, SUM(purchase_item_total) AS total_spent
FROM customers LEFT JOIN purchases ON (customers.customer_username=purchases.customer_username)
GROUP BY customer_name
ORDER BY customer_name;

-- Decreases inventory of purchased items by 1 (i.e. when it's purchased).
UPDATE product_inventory 
SET quantity=quantity - 1
WHERE product_id IN (SELECT product_id FROM purchases);