from datetime import datetime

from flask import *
from flask_cors import CORS
from flask_login import LoginManager, login_user, logout_user, login_required, current_user

from peewee import MySQLDatabase
import yaml

from models import db
from models import User

app = Flask(__name__)

secrets = yaml.load(open('./secrets.yaml'))
app_secrets = secrets['app']
app.secret_key = app_secrets['secret_key']

CORS(app)

# Flask-login

login_manager = LoginManager()
login_manager.init_app(app)
login_manager.login_view = 'login'

@login_manager.user_loader
def load_user(user_id):
    # May return None if no user exists.
    return User.get(User.email == user_id)

# Database lifecycle

@app.before_request
def _db_connect():
    if db.is_closed():
        db.connect()

@app.teardown_request
def _db_close(exc):
    if not db.is_closed():
        db.close()

# Testing

def create_tables():
    # Create tables based on the following User models if they don't already exist.
    db.create_tables([User], safe=True)

# Frontend routes

@app.route('/')
def index():
    if not current_user.is_authenticated:
        return redirect('/login')

    return "We're logged in, show whatever html you want."

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'GET':
        return render_template('login.html')

    email = request.form['email']
    password = request.form['password']

    user = User.login(email=email, password=password)

    if user:
        login_user(user)
        return redirect('/')
    else:
        return redirect('/login')

@app.route('/signup', methods=['GET', 'POST'])
def signup():
    if request.method == 'GET':
        return render_template('signup.html')

    name = request.form['name']
    email = request.form['email']
    password = request.form['password']

    existing_user = User.get_or_none(User.email == email)
    if existing_user:
        return "This user already exists."

    new_user = User.create(email, name, password)

    if new_user:
        login_user(new_user)
        return redirect('/')
    else:
        return redirect('/signup')

@app.route('/logout')
def logout():
    logout_user()
    return redirect('/login')

@login_required
@app.route('/api/test', methods=['GET'])
def test_login():
    if not current_user.is_authenticated:
        abort(403)

    return jsonify({'status': 'logged_in', 'user': current_user.to_dict()}), 200

@login_required
@app.route('/api/user', methods=['GET'])
def get_user_data():
    if not current_user.is_authenticated:
        abort(403)

    print("Getting user data for {}".format(current_user.name))
    return jsonify(current_user.to_dict())

if __name__ == '__main__':
    app.run(debug=True)
