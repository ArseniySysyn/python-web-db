from flask import Flask, render_template, request
import mysql.connector, os

app = Flask(__name__)

USERNAME = os.environ.get('DB_USERNAME')
PASSWORD = os.environ.get('DB_PASSWORD')
ENDPOINT = os.environ.get('DB_ENDPOINT')[:-5]

# Set up the MySQL connection
mydb = mysql.connector.connect(
  host=ENDPOINT,
  user=USERNAME,
  password=PASSWORD,
  database="mydb"
)

# Create the "users" table if it doesn't exist
mycursor = mydb.cursor()
mycursor.execute("CREATE TABLE IF NOT EXISTS users (id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(255), surname VARCHAR(255), age INT)")

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/submit', methods=['POST'])
def submit():
    name = request.form.get('name')
    surname = request.form.get('surname')
    age = request.form.get('age')

    # Insert the data into the "users" table
    sql = "INSERT INTO users (name, surname, age) VALUES (%s, %s, %s)"
    val = (name, surname, age)
    mycursor.execute(sql, val)
    mydb.commit()

    sql = "SELECT * FROM users"
    mycursor.execute(sql)
    result = mycursor.fetchall()
    return render_template("all_data.html", data=result)


@app.route("/all_data", methods=['GET'])
def show_all_data():
    sql = "SELECT * FROM users"
    mycursor.execute(sql)
    result = mycursor.fetchall()
    return render_template("all_data.html", data=result)

@app.route("/delete/<int:user_id>", methods=['POST'])
def delete(user_id):
    # Delete row with specified user_id from the database
    sql = "DELETE FROM users WHERE id = %s"
    values = (user_id,)
    mycursor.execute(sql, values)
    mydb.commit()

    # Redirect user to page that displays all data in the database
    sql = "SELECT * FROM users"
    mycursor.execute(sql)
    result = mycursor.fetchall()
    return render_template("all_data.html", data=result)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
