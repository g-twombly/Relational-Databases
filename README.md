# Relational Database Project README
## Authors: Gabriella Twombly and Ellen Min
The goal of the project was to create a database that replicated a LEGO store.
The database supports a certain number of command-line queries as well as
employee and customer logins. Follow the instructions below to try it out
for yourself. Thank you!

## Data source:
https://www.kaggle.com/datasets/rtatman/lego-database?select=parts.csv


NOTE: THIS PROGRAM IS TESTED ON SQL 5.7 (MAMP SQL).

## Instructions for loading data on command-line:
Make sure you have MySQL downloaded and available through your
device's command-line.

First, create an appropriate database in mySQL:

mysql> CREATE DATABASE legos;

mysql> USE legos;

Not including the "mysql>" prompt, run the following lines of code on your command-line
after creating and using an appropriate database:

mysql> source setup.sql;

mysql> source load-data.sql;

mysql> source setup-passwords.sql;

mysql> source setup-routines.sql;

mysql> source grant-permissions.sql;

mysql> source queries.sql;


## Instructions for Python program:
Please install the Python MySQL Connector using pip3 if not installed already.

After loading the data and verifying you are in the correct database, run the following to open the python application:

mysql> quit;

$ python3 app_client.py

OR

$ python3 app_admin.py

Please log in with the following user/passwords:

For app_client.py, the following customers are registered:

    USER | PASSWORD
    
    mfreeman | mfreemanpw
    
    cpratt | cprattpw
    
    wferrell | wferrellpw
    
    ebanks | ebankspw
    
    warnett | warnettpw

For app_admin.py, the following admins are registered:

    USER | PASSWORD
    
    emin | eminpw
    
    gtwombly | gtwomblypw 
    

## Supported Usage:
Here is a suggested guide to using app_client.py:

    1.  Select option [a] to learn more about some products.
    
    2. Remember a product ID you want to buy!
    
    3. Select option [b] to purchase that item.
    
    4. Remember your purchase ID.
    
    5. Select option [d] to write a review using your purchase ID.
    
    6. Select option [c] to request a product.

Here is a suggested guide to using app_admin.py:

    1. Select option [a] to see which requests are unfulfilled.
    
    2. Remember a request ID you want to fulfill.
    
    3. Select option [b] to fulfill that request.
    
    4. Select option [c] to see how much money you've made!
    

## Files written to user's system:

- No files are written to the user's system.
