-- DROP STATEMENTS
DROP TABLE IF EXISTS user_info;

DROP FUNCTION IF EXISTS make_salt;
DROP FUNCTION IF EXISTS authenticate;

DROP PROCEDURE IF EXISTS sp_add_user;
DROP PROCEDURE IF EXISTS sp_change_password;


-- File for Password Management section of Final Project
-- (Provided) This function generates a specified number of characters 
-- for using as a salt in passwords.
DELIMITER !

CREATE FUNCTION make_salt(num_chars INT) 
RETURNS VARCHAR(20) NOT DETERMINISTIC
BEGIN
    DECLARE salt VARCHAR(20) DEFAULT '';
    -- Don't want to generate more than 20 characters of salt.
    SET num_chars = LEAST(20, num_chars);
    -- Generate the salt!  Characters used are ASCII code 32 (space)
    -- through 126 ('z').
    WHILE num_chars > 0 DO
        SET salt = CONCAT(salt, CHAR(32 + FLOOR(RAND() * 95)));
        SET num_chars = num_chars - 1;
    END WHILE;
    RETURN salt;
END !

DELIMITER ;

-- Provided (you may modify if you choose)
-- This table holds information for authenticating users based on
-- a password.  Passwords are not stored plaintext so that they
-- cannot be used by people that shouldn't have them.
-- You may extend that table to include an is_admin or role attribute if you 
-- have admin or other roles for users in your application 
-- (e.g. store managers, data managers, etc.)

CREATE TABLE user_info (
    -- Usernames are up to 20 characters.
    username VARCHAR(20) PRIMARY KEY,
    -- Salt will be 8 characters all the time, so we can make this 8.
    salt CHAR(8) NOT NULL,
    -- We use SHA-2 with 256-bit hashes.  MySQL returns the hash
    -- value as a hexadecimal string, which means that each byte is
    -- represented as 2 characters.  Thus, 256 / 8 * 2 = 64.
    -- We can use BINARY or CHAR here; BINARY simply has a different
    -- definition for comparison/sorting than CHAR.
    password_hash BINARY(64) NOT NULL
);


-- Adds a new user to the user_info table, using the specified password (max
-- of 20 characters). Salts the password with a newly-generated salt value,
-- and then the salt and hash values are both stored in the table.
DELIMITER !

CREATE PROCEDURE sp_add_user(new_username VARCHAR(20), password VARCHAR(20)) NOT DETERMINISTIC
BEGIN
    -- initialize values
    DECLARE new_salt CHAR(8);
    DECLARE hold_salt VARCHAR(28);
    DECLARE salted_pass BINARY(64);

    -- use helper to generate a new salt
    SET new_salt = make_salt(8);
    -- prepend salt to password before hashing
    SET hold_salt = CONCAT(new_salt, password);
    -- built-in function will generate 256 bit hashes
    SET salted_pass = SHA2(hold_salt, 256);

    INSERT INTO user_info VALUES (new_username, new_salt, salted_pass);
END !

DELIMITER ;


-- Authenticates the specified username and password against the data
-- in the user_info table.  Returns 1 if the user appears in the table, 
-- and the specified password hashes to the value for the user. 
-- Otherwise returns 0.
DELIMITER !

CREATE FUNCTION authenticate(user VARCHAR(20), password VARCHAR(20))
RETURNS TINYINT DETERMINISTIC
BEGIN
    -- initialize values
    DECLARE a_salt CHAR(8);
    DECLARE hold_salt VARCHAR(28);
    DECLARE salted_pw BINARY(64);
    
    -- if user does not exist in database, return 0
    IF NOT EXISTS(SELECT * FROM user_info WHERE username = user) THEN
        RETURN 0;
    END IF;
  
    SELECT salt, password_hash INTO a_salt, salted_pw FROM user_info 
    WHERE username = user LIMIT 1;
    SET hold_salt = CONCAT(a_salt, password);
  
    -- if hash matches hash stored in database, return 1
    -- if not, return 0
    IF SHA2(hold_salt, 256) = salted_pw THEN
        RETURN 1;
    END IF;
  
    RETURN 0;
END !

DELIMITER ;


-- Optional: Create a procedure sp_change_password to generate a new salt and 
-- change the given user's password to the given password (after salting and 
-- hashing)
DELIMITER !

CREATE PROCEDURE sp_change_password(usr VARCHAR(20), pass VARCHAR(20)) NOT DETERMINISTIC
BEGIN
    -- initialize values
    DECLARE new_salt CHAR(8);
    DECLARE hold_salt VARCHAR(28);
    DECLARE salted_pass BINARY(64);

    -- use helper to generate a new salt
    SET new_salt = make_salt(8);
    -- prepend salt to password before hashing
    SET hold_salt = CONCAT(new_salt, pass);
    -- built-in function will generate 256 bit hashes
    SET salted_pass = SHA2(hold_salt, 256);

    UPDATE user_info SET salt = new_salt, password_hash = salted_pass
    WHERE username = usr;
END !

DELIMITER ;

-- Add at least two users into your user_info table so that when we 
-- run this file, we will have examples users in the database.
CALL sp_add_user('emin', 'eminpw');
CALL sp_add_user('gtwombly', 'gtwomblypw');

CALL sp_add_user('mfreeman', 'mfreemanpw');
CALL sp_add_user('cpratt', 'cprattpw');
CALL sp_add_user('ebanks', 'ebankspw');
CALL sp_add_user('wferrell', 'wferrellpw');
CALL sp_add_user('warnett', 'warnettpw');