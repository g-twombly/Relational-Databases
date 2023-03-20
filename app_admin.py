"""
Student name(s): Ellen Min, Gabriella Twombly
Student email(s): emin@caltech.edu, gtwombly@caltech.edu

Provides a program to help admins (i.e. lego store employees) 
interact with the lego store. 

Admins (employees) can fulfill requests and view the total 
revenue of the store.
"""

import sys 
import mysql.connector
import mysql.connector.errorcode as errorcode

DEBUG = False


# ----------------------------------------------------------------------
# SQL Utility Functions
# ----------------------------------------------------------------------
def get_conn():
    """
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
            sys.stderr("An error occurred, please contact mySQL.")
        sys.exit(1)


# ----------------------------------------------------------------------
# Functions for Command-Line Options/Query Execution
# ----------------------------------------------------------------------
def view_requests():
    """
    View UNFULFILLED requests.
    """
    print("\n-----------------------------------------------------\n")
    print("Here is a list of unfulfilled request IDs and the products they are requesting:")
    try:
        cursor = conn.cursor()
        
        sql = """SELECT request_id, product_id FROM requests WHERE request_status='U'"""
        cursor.execute(sql)
        rows = cursor.fetchall()
        for row in rows:
            (req_id, prod_id) = row 
            print("\nRequest #{req} requesting product #{prod}.".format(req=req_id, prod=prod_id))

    except mysql.connector.Error as err:
        if DEBUG:
            sys.stderr(err)
            sys.exit(1)
        else:
            sys.stderr("An error occurred! Please contact technical support.")


def view_revenue():
    """
    View total revenue of store.
    """
    try:
        cursor = conn.cursor()
        result = cursor.callproc("show_total_revenue", [0])
        print("\n-----------------------------------------------------\n")
        print("The total revenue from this store is: ${rev}.".format(rev=result[0]))

    except mysql.connector.Error as err:
        if DEBUG:
            sys.stderr(err)
            sys.exit(1)
        else:
            sys.stderr("An error occurred! Please contact technical support.")


def validate_request(request_id):
    """
    Helper function. 
    Checks whether request exists, and is unfulfilled.
    """
    if not request_id.isdigit():
        return False 
    
    try:
        cursor = conn.cursor()
        
        sql = """SELECT request_id FROM requests WHERE request_status='U'"""
        cursor.execute(sql)
        rows = cursor.fetchall()
        for row in rows:
            (req_id) = row 
            if (int(request_id)==req_id[0]):
                return True
        return False 
    
    except mysql.connector.Error as err:
        if DEBUG:
            sys.stderr(err)
            sys.exit(1)
        else:
            sys.stderr("An error occurred! Please contact technical support.")


def fulfill_request():
    """
    Fulfills request for a product.
    Increases inventory by 1.
    Updates the log.
    """
    request_id = input("\nWhat is the ID of the request you're fulfilling? ")
    while not validate_request(request_id):
        print("\nINVALID REQUEST ID!")
        print("Most likely, that request doesn't exist, or you have already fulfilled it.")
        request_id = input("\nNow, please enter your desired request ID: ")

    try:
        cursor = conn.cursor()
        cursor.callproc("fulfill_request", [request_id])
        conn.commit()  # Call to commit this change to log.

        print("\n-----------------------------------------------------\n")
        print("Request successfully fulfilled.")
    except mysql.connector.Error as err:
        # If you're testing, it's helpful to see more details printed.
        if DEBUG:
            sys.stderr(err)
            sys.exit(1)
        else:
            sys.stderr("An error occurred! Please contact an employee.")


# ----------------------------------------------------------------------
# Functions for Logging Users In
# ----------------------------------------------------------------------
def is_employee(username):
    """
    Helper function.
    Checks that person logging in is an employee.
    """
    cursor = conn.cursor()
    sql = "SELECT employee_username FROM employees WHERE employee_username='%s';" % (username, )
    cursor.execute(sql)
    results = cursor.fetchall()
    
    return (len(results) > 0)


def logging_in():
    """
    Prompts for login from admin user. 
    Checks database to make sure user and password are correct.
    Assumes employees are the only ones with access to this Python file.
    """
    cursor = conn.cursor()

    print("\n-------------------------- LEGO STORE ADMIN LOGIN --------------------------\n")

    while True:
        username = input("USERNAME: ").lower()
        password = input("PASSWORD: ").lower()

        while not is_employee(username):
            print("\nHmm, it doesn't look like you are an employee. Try again!\n")
            username = input("USERNAME: ").lower()
            password = input("PASSWORD: ").lower()

        sql = "SELECT authenticate('%s', '%s');" % (username, password)

        try:
            cursor.execute(sql)
            check_response = cursor.fetchone()

            if check_response[0] == 1:
                show_options()
            else:
                print("\nWRONG USERNAME OR PASSWORD. TRY AGAIN!\n")

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
    Helps admins navigate the store. They can:
        1. Fulfill requests.
        2. View total revenue of the store.
    """
    print("\n-----------------------------------------------------\n")
    print("HELLO AND WELCOME TO LEGO ADMINISTRATION! :)")

    while True:
        print("\n-----------------------------------------------------\n")
        print("What best describes you?\n")
        print("  [a] - I want to see all unfulfilled requests.")
        print("  [b] - I want to fulfill a request for a customer.")
        print("  [c] - I want to see the total revenue of this store.")
        print("  [q] - Exit this app.")
        print()
        ans = input("Enter an option: ").lower()
        if ans == "a":
            view_requests()
        if ans == "b":
            fulfill_request()
        elif ans == "c":
            view_revenue()
        elif ans == "q":
            quit_ui()


def quit_ui():
    """
    Quits the program, printing a good bye message to the user.
    """
    print("\n-----------------------------------------------------\n")
    print("Thanks for managing the LEGO Store!")
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
