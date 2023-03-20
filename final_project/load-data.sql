-- DISCLAIMER: INSTRUCTIONS AND CODE ARE MODIFIED FROM A3/load-spotify.sql.

-- Instructions:
-- This script will load all CSV files into setup.sql.
-- Intended for use with the command-line MySQL, otherwise unnecessary for
-- phpMyAdmin (just import each CSV file in the GUI).

-- Make sure this file is in the same directory as all CSV files
-- setup.sql. Then run the following in the mysql> prompt (assuming
-- you have a legodb created with CREATE DATABASE legodb;):
-- USE DATABASE legodb; 
-- source setup.sql; (make sure no warnings appear)
-- source load-data.sql; (make sure there are 0 skipped/warnings)

LOAD DATA LOCAL INFILE 'employees.csv' INTO TABLE employees 
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\r\n';

LOAD DATA LOCAL INFILE 'discounts.csv' INTO TABLE discounts 
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n';

LOAD DATA LOCAL INFILE 'customers.csv' INTO TABLE customers 
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n';

LOAD DATA LOCAL INFILE 'product_inventory.csv' INTO TABLE product_inventory 
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n';

LOAD DATA LOCAL INFILE 'categories.csv' INTO TABLE categories 
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\r\n';

LOAD DATA LOCAL INFILE 'themes.csv' INTO TABLE themes
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n';

LOAD DATA LOCAL INFILE 'lego_sets.csv' INTO TABLE lego_sets
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n';

LOAD DATA LOCAL INFILE 'lego_parts.csv' INTO TABLE lego_parts
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n';

LOAD DATA LOCAL INFILE 'requests.csv' INTO TABLE requests
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n';

LOAD DATA LOCAL INFILE 'purchases.csv' INTO TABLE purchases
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n';

LOAD DATA LOCAL INFILE 'reviews.csv' INTO TABLE reviews
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\r\n';