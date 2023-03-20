-- Granting permissions to customers and employees in LEGO store
DROP USER IF EXISTS 'emin'@'localhost';
DROP USER IF EXISTS 'gtwombly'@'localhost';
DROP USER IF EXISTS 'mfreeman'@'localhost';
DROP USER IF EXISTS 'ebanks'@'localhost';
DROP USER IF EXISTS 'wferrell'@'localhost';
DROP USER IF EXISTS 'warnett'@'localhost';
DROP USER IF EXISTS 'cpratt'@'localhost';

-- Creates employees
CREATE USER 'emin'@'localhost' IDENTIFIED BY 'eminpw';
CREATE USER 'gtwombly'@'localhost' IDENTIFIED BY 'gtwomblypw';

-- Creates a customer user (Morgan Freeman, who starred in the LEGO movie).
CREATE USER 'mfreeman'@'localhost' IDENTIFIED BY 'mfreemanpw';
CREATE USER 'ebanks'@'localhost' IDENTIFIED BY 'ebankspw';
CREATE USER 'wferrell'@'localhost' IDENTIFIED BY 'wferrellpw';
CREATE USER 'warnett'@'localhost' IDENTIFIED BY 'warnettpw';
CREATE USER 'cpratt'@'localhost' IDENTIFIED BY 'cprattpw';


GRANT ALL PRIVILEGES ON legos.* TO 'emin'@'localhost';
GRANT ALL PRIVILEGES ON legos.* TO 'gtwombly'@'localhost';

GRANT SELECT ON legos.* TO 'mfreeman'@'localhost';
GRANT SELECT ON legos.* TO 'ebanks'@'localhost';
GRANT SELECT ON legos.* TO 'wferrell'@'localhost';
GRANT SELECT ON legos.* TO 'warnett'@'localhost';
GRANT SELECT ON legos.* TO 'cpratt'@'localhost';

FLUSH PRIVILEGES;