"""
Student name(s): Ellen Min, Gabriella Twombly
Student email(s): emin@caltech.edu, gtwombly@caltech.edu

Provides a program to help clients (i.e potential customers) interact 
with the lego store. 

Customers can query, request, purchase, and review products.
"""

import random
import sys
import mysql.connector
import mysql.connector.errorcode as errorcode

CURR_USERNAME = ""

DEBUG = False

# ----------------------------------------------------------------------
# SQL Utility Functions
# ----------------------------------------------------------------------
def get_conn():
    """ "
    Returns a connected MySQL connector instance, if connection is successful.
    If unsuccessful, exits.
    """
    try:
        conn = mysql.connector.connect(
            host="localhost",
            user="emin",
            port="8889",  # this may change!
            password="eminpw",
            database="legos",
        )
        if DEBUG:
            print("Successfully connected.")
        return conn
    except mysql.connector.Error as err:
        if err.errno == errorcode.ER_ACCESS_DENIED_ERROR and DEBUG:
            sys.stderr("Incorrect username or password when connecting to DB.")
        elif err.errno == errorcode.ER_BAD_DB_ERROR and DEBUG:
            sys.stderr("Database does not exist.")
        elif DEBUG:
            sys.stderr(err)
        else:
            sys.stderr("An error occurred, please contact the administrator.")
        sys.exit(1)


# ----------------------------------------------------------------------
# Functions for Command-Line Options/Query Execution
# ----------------------------------------------------------------------
def search_for_sets():
    """ 
    Helps users query sets.
    Presents several options for searching for sets.
    """
    print("\n-----------------------------------------------------\n")
    print("Which of the following questions can I help you with?\n")
    print("  [a] - I have a maximum price in mind. What can I buy?")
    print("  [b] - I have a theme I want to explore. What sets are in that theme?")
    print("  [c] - I have a product I want. How much does it cost? And what did other users rate it?")
    print("  [q] - Quit.")
    print()

    ans = input("Enter an option: ").lower()
    if ans == "a":
        max_price = input("\nEnter your maximum budget ($): ")
        while not (max_price.isnumeric() and float(max_price) <= 200 
                   and float(max_price) > 0):
            max_price = input("\nSorry, we only accept numbers between 1 and 200 (inclusive).\n"
                              + "Again, enter your maximum budget ($): ")
        search_with_budget(max_price)
    elif ans == "b":
        theme_name = input("\nWhat theme are you interested in? \n"
                        + "(Examples: Super Heroes, Marvel, Star Wars)\n\n")
        search_for_themes(theme_name)
    elif ans == "c":
        prod_id = input("\nEnter the product ID of the product you're interested in: ")
        is_set = int(prod_id) >= 1 and int(prod_id) <= 11673
        is_part = int(prod_id) >= 100000 and int(prod_id) <= 125992
        while not (prod_id.isdigit() and (is_set or is_part)):
            prod_id = input("\nSorry, set IDs are integers between 1 and 11673 (inclusive).\n"
                            + "Part IDs are integers between 100000 and 125992.\n"
                            + "Again, enter the product ID you wish to query: ")
        get_price_rating(prod_id)
    else:
        quit_ui()


def pick_n_random(n, rows):
    """
    Helper function to show users digestible data.
    Picks n random rows from a dataset.
    """
    res = []
    rand_indices = random.sample(range(len(rows)), n)
    for i in rand_indices:
        res.append(rows[i])
    return res


def get_price_rating(prod_id):
    """
    Gets the price and average rating for a product.
    """
    try:
        cursor = conn.cursor()
        result = cursor.callproc("get_price_and_rating", [prod_id, 0, 0])

        print("\n-----------------------------------------------------\n")
        print("The set costs ${price}.".format(price=result[1]))

        rating = result[2]
        if rating == 0:
            print("There are currently no ratings for that product.")
        else:
            print("Its average rating is {star} stars.".format(star=rating))

    except mysql.connector.Error as err:
        if DEBUG:
            sys.stderr(err)
            sys.exit(1)
        else:
            sys.stderr("An error occurred! Please contact an employee.")


def search_for_themes(theme_name):
    """
    Searches for sets with a given theme.
    """
    print("\n-----------------------------------------------------\n")

    try:
        cursor = conn.cursor()
        cursor.callproc("get_sets_in_theme", [theme_name])
        results = cursor.stored_results()

        for result in results:
            rows = result.fetchall()
            if len(rows) == 0:
                print("Sorry, there are no sets in that theme.")
                print("Try again with another theme next time?")
            else: 
                print("Here are some sets you might get interested in.")
                sample_rows = pick_n_random(min(len(rows), 5), rows)
                for row in sample_rows:
                    (product_id, product_name, product_price) = row
                    print('\nThe "{name}" set is ${price}.'.format(
                            name=product_name, price=product_price))
                    print("Remember this product ID to purchase: {id}.".format(
                            id=product_id))

    except mysql.connector.Error as err:
        if DEBUG:
            sys.stderr(err)
            sys.exit(1)
        else:
            sys.stderr("An error occurred! Please contact an employee.")


def search_with_budget(max_price):
    """
    Returns 5 random sets with a price under max_price.
    """
    print("\n-----------------------------------------------------\n")
    try:
        cursor = conn.cursor()
        cursor.callproc("get_sets_max_price", [max_price])

        for result in cursor.stored_results():
            rows = result.fetchall()
            if len(rows) == 0:
                print("Actually, nevermind. There are no sets within your budget. Sorry!")
            else:
                sample_rows = pick_n_random(min(len(rows), 5), rows)
                print("Here are some options for you:")
                for row in sample_rows:
                    (product_id, product_name, product_price) = row
                    print('\nThe "{name}" set is ${price}.'.format(
                            name=product_name, price=product_price))
                    print("Remember this product ID to purchase: {id}.".format(
                            id=product_id))

    except mysql.connector.Error as err:
        if DEBUG:
            sys.stderr(err)
            sys.exit(1)
        else:
            sys.stderr("An error occurred! Please contact an employee.")

def valid_product_request(product_id, is_purchase):
    """
    Helper function. 
    Checks whether there is enough inventory for the purchase,
    and whether the product ID is the correct format.

    If is_purchase, then returns if there is > 0 in inventory.
    If is_request, then returns if there is < 1 in inventory.
    """
    if not product_id.isdigit():
        return False
    is_set = int(product_id) >= 1 and int(product_id) <= 11673
    is_part = int(product_id) >= 100000 and int(product_id) <= 125992
    if not (is_set or is_part):
        return False

    cursor = conn.cursor()
    sql = "SELECT quantity FROM product_inventory WHERE product_id=%s;" % (product_id, )
    cursor.execute(sql)
    available_inventory = cursor.fetchone()[0]

    if is_purchase:
        return (available_inventory > 0)
    else:
        return (available_inventory <= 0)


def make_purchase():
    """
    Allows users to purchase a product if they know the product ID.
    """
    prod_id = input("\nPlease enter the product ID of the item you wish to purchase: ")
    while not valid_product_request(prod_id, True):
        prod_id = input("\nSORRY, YOU HAVE ENTERED AN INVALID PRODUCT ID, OR THE ITEM IS OUT OF STOCK.\n"
                        + "\nSet IDs are integers between 1 and 11673 (inclusive), and "
                        + "part IDs are integers between 100000 and 125992.\n"
                        + "Remember, you can always request an out-of-stock product!\n"
                        + "\nAgain, enter the product ID you wish to purchase: ")

    try:
        cursor = conn.cursor()
        cursor.callproc("make_purchase", [prod_id, CURR_USERNAME])
        conn.commit()

        sql = """SELECT purchase_id FROM purchases ORDER BY purchase_id DESC LIMIT 1"""
        cursor.execute(sql)
        pur_id = cursor.fetchone()[0]

        print("\n-----------------------------------------------------\n")
        print("Thanks for your purchase!\n")
        print("Remember your purchase ID to write a review: {id}.".format(id=pur_id))

    except mysql.connector.Error as err:
        if DEBUG:
            sys.stderr(err)
            sys.exit(1)
        else:
            sys.stderr("An error occurred! Please contact an employee.")


def make_request():
    """
    Allows customers to request a product given the product ID.
    """
    print("\n(NOTE FOR GRADERS: Some product IDs with 0 stock (initially) are 7, 18, and 10135.)")
    prod_id = input("\nPlease enter the product ID of the item you wish to request: ")
    while not valid_product_request(prod_id, False):
        prod_id = input("\nSORRY, YOU ENTERED AN INVALID PRODUCT ID, OR THE ITEM IS ALREADY IN STOCK.\n"
                        + "Again, enter the product ID you wish to request: ")

    try:
        cursor = conn.cursor()
        cursor.callproc("request_additional_inventory", [prod_id, CURR_USERNAME])
        conn.commit()

        print("\n-----------------------------------------------------\n")
        print("Request has been successfully made.")

    except mysql.connector.Error as err:
        if DEBUG:
            sys.stderr(err)
            sys.exit(1)
        else:
            sys.stderr("An error occurred! Please contact an employee.")


def validate_review_purchase(purchase_id):
    """
    Helper function. 
    Checks whether purchase has been reviewed already,
    and whether current customer actually made that purchase.
    """
    if not (purchase_id.isdigit() and int(purchase_id) > 0):
        return False 
    
    no_review_yet = False
    matching_customer = False

    cursor = conn.cursor()

    sql = "SELECT * FROM reviews WHERE purchase_id=%s;" % (purchase_id, )
    cursor.execute(sql)
    potential_duplicate = cursor.fetchall()
    no_review_yet = len(potential_duplicate) == 0

    sql = "SELECT purchase_id FROM purchases WHERE customer_username='%s';" % (CURR_USERNAME, )
    cursor.execute(sql)
    customer_purchases = cursor.fetchall()
    for purchase in customer_purchases:
        if purchase[0]==int(purchase_id):
            matching_customer = True

    return (no_review_yet and matching_customer)


def write_review():
    """
    Allows customers to write a review for a product.
    Customers cannot write duplicate reviews.
    """
    purchase_id = input("\nPlease enter the purchase ID of the purchase you're reviewing: ")
    while not validate_review_purchase(purchase_id):
        print("\nINVALID PURCHASE ID!")
        print("Most likely, that purchase already has a review, or you didn't make that purchase.")
        purchase_id = input("\nNow, please enter the desired purchase ID again: ")

    rating = input("\nHow would you rate this product? Please enter an integer 1-5: ")
    while not (rating.isdigit() and int(rating) <= 5 and int(rating) >= 1):
        rating = input("\nSorry, we only accept integers between 1 and 5 (inclusive).\n"
                        + "Again, enter your rating: ")
        
    review = input("\nPlease enter a brief review that is less than 500 characters: ")

    try:
        cursor = conn.cursor()
        cursor.callproc("write_review", [purchase_id, rating, review])
        conn.commit()

        print("\n-----------------------------------------------------\n")
        print("Thanks for your review!")

    except mysql.connector.Error as err:
        if DEBUG:
            sys.stderr(err)
            sys.exit(1)
        else:
            sys.stderr("An error occurred! Please contact an employee.")


# ----------------------------------------------------------------------
# Functions for Logging Users In
# ----------------------------------------------------------------------
def is_customer(username):
    """
    Helper function.
    Checks that person logging in is a customer.
    """
    cursor = conn.cursor()
    sql = "SELECT customer_username FROM customers WHERE customer_username='%s';" % (username, )
    cursor.execute(sql)
    results = cursor.fetchall()
    
    return (len(results) > 0)

def logging_in():
    """
    Prompts for login from user. 
    Checks database to make sure they enter valid username and password.
    """
    cursor = conn.cursor()

    print("\n-------------------------- LEGO STORE CUSTOMER LOGIN --------------------------\n")

    while True:
        username = input("USERNAME: ").lower()
        global CURR_USERNAME
        CURR_USERNAME = username
        password = input("PASSWORD: ").lower()

        while not is_customer(username):
            print("\nHmm, it doesn't look like you are a registered customer. Try again!\n")
            username = input("USERNAME: ").lower()
            CURR_USERNAME = username
            password = input("PASSWORD: ").lower()

        sql = """SELECT authenticate('%s', '%s');""" % (username, password)

        try:
            cursor.execute(sql)
            check_response = cursor.fetchone()

            if check_response[0] == 1:
                show_options()
            else:
                print("\n-----------------------------------------------------\n")
                print("WRONG USERNAME OR PASSWORD. TRY AGAIN!\n")
        except mysql.connector.Error as err:
            if DEBUG:
                sys.stderr(err)
                sys.exit(1)
            else:
                sys.stderr("Error logging in.")


# ----------------------------------------------------------------------
# Command-Line Functionality
# ----------------------------------------------------------------------
def show_options():
    """
    Helps customers navigate the store. They can:
        1. Search for sets
        2. Purchase an item
        3. Make a request
        4. Write a review.
    """
    print("\n-----------------------------------------------------\n")
    print("HELLO AND WELCOME TO THE LEGO STORE! :)")

    while True:
        print("\n-----------------------------------------------------\n")
        print("What best describes you?\n")
        print("  [a] - I want to learn more about some product(s).")
        print("  [b] - I know what I want to buy!")
        print("  [c] - I want to request an item that's out of stock.")
        print("  [d] - I want to review one of my purchases!")
        print("  [q] - Exit this app.")
        print()

        ans = input("Enter an option: ").lower()

        if ans == "a":
            search_for_sets()
        elif ans == "b":
            make_purchase()
        elif ans == "c":
            make_request()
        elif ans == "d":
            write_review()
        elif ans == "q":
            quit_ui()


def quit_ui():
    """
    Quits the program, printing a good bye message to the user.
    """
    print("\n-----------------------------------------------------\n")
    print("Thanks for visiting the LEGO Store!")
    print("\n-----------------------------------------------------\n")
    exit()


def main():
    """
    Main function for starting things up.
    """
    logging_in()


if __name__ == "__main__":
    conn = get_conn()
    main()