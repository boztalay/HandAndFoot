from datetime import datetime

from flask import *
from flask_cors import CORS
from flask_login import LoginManager, login_user, logout_user, login_required, current_user

from peewee import MySQLDatabase
import yaml

from models import db
from models import User
from models import Game
from models import UserGame
from models import Action

#
# Setup
#

app = Flask(__name__)

secrets = yaml.load(open('./secrets.yaml'))
app_secrets = secrets['app']
app.secret_key = app_secrets['secret_key']

CORS(app)

#
# Flask-login
#

login_manager = LoginManager()
login_manager.init_app(app)
login_manager.login_view = 'login'

@login_manager.user_loader
def load_user(user_id):
    # May return None if no user exists.
    return User.get_or_none(User.email == user_id)

#
# Database Lifecycle
#

@app.before_request
def _db_connect():
    if db.is_closed():
        db.connect()

@app.teardown_request
def _db_close(exc):
    if not db.is_closed():
        db.close()

#
# Testing
#

def create_tables():
    # Create tables based on the following User models if they don't already exist.
    db.create_tables([User, Game, UserGame, Action], safe=True)

#
# Frontend Routes
#

# Home Page

@app.route('/')
def index():
    if not current_user.is_authenticated:
        return redirect('/login')

    return "We're logged in, show whatever html you want."

# Account Management

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

@login_required
@app.route('/profile', methods=['GET'])
def get_user_profile():
    if not current_user.is_authenticated:
        abort(403)

    print("Getting user data for {}".format(current_user.name))
    return jsonify(current_user.to_dict())

@app.route('/logout')
def logout():
    logout_user()
    return redirect('/login')

# Synchronization

@login_required
@app.route('/api/sync', methods=['GET'])
def sync_user():
    if not current_user.is_authenticated:
        abort(403)

    return "TODO"

# Game Management

@login_required
@app.route('/api/game/create', methods=['POST'])
def create_game():
    if not current_user.is_authenticated:
        abort(403)

    user_emails = request.args.get('users')
    if user_emails is None:
        abort(400)

    user_emails = user_emails.split(';')
    if len(user_emails) < 1 or len(user_emails) > 5:
        abort(400)

    users = []
    for user_email in user_emails:
        user = Users.get_or_none(User.email == user_email)
        if user is None:
            abort(400)
        else:
            users.append(user)

    game = Game.create()

    for user in users:
        usergame = UserGame.create(user, game)

    return Response(status=201)

@login_required
@app.route('/api/game/accept', methods=['POST'])
def accept_game_invite():
    if not current_user.is_authenticated:
        abort(403)

    game_id = request.args.get('game')
    if game_id is None:
        abort(400)

    game = Game.get_or_none(Game.id == game_id)
    if game is None:
        abort(400)

    usergame = UserGame.get_or_none(UserGame.user == current_user, UserGame.game == game)
    if usergame is None:
        abort(400)

    usergame.user_accepted = True
    usergame.save()

    return Response(status=200)

@login_required
@app.route('/api/game/add_action', methods=['POST'])
def add_action_to_game():
    if not current_user.is_authenticated:
        abort(403)

    return "TODO"

#
# Main
#

if __name__ == '__main__':
    app.run(debug=True)
