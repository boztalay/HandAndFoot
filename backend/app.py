from datetime import datetime

from flask import *
from flask_cors import CORS
from flask_login import LoginManager, login_user, logout_user, login_required, current_user
from itsdangerous import Signer

from peewee import MySQLDatabase
import yaml

from models import db
from models import UserRole
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
# Flask-Login
#

login_manager = LoginManager()
login_manager.init_app(app)
login_manager.login_view = 'login'

@login_manager.user_loader
def load_user(user_id):
    return User.get_or_none(User.email == user_id)

#
# Token Authentication
#

def token_required(function):
    def wrapper(*args, **kwargs):
        api_token = request.headers.get('X-App-Token')

        if not api_token:
            return (jsonify({'success': False, 'message': 'No API token found in request'}), 400)

        try:
            from models import TOKEN_SIGNING_KEY
            s = Signer(TOKEN_SIGNING_KEY)
            email = s.unsign(api_token).decode('utf-8')

            user = User.get(User.email == email)

            kwargs['current_user'] = user
            login_user(user)
        except Exception as e:
            print(e)
            return (jsonify({'success': False, 'message': 'Invalid request.'}), 400)

        return function(*args, **kwargs)

    wrapper.__name__ = function.__name__
    return wrapper

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

# Account Management

@app.route('/api/signup', methods=['POST'])
def signup():
    name = request.form['name']
    email = request.form['email']
    password = request.form['password']

    existing_user = User.get_or_none(User.email == email)
    if existing_user:
        return (jsonify({'success': False, 'message': "User already exists"}), 403)

    new_user = User.create(email, name, password)

    if new_user:
        login_user(new_user)
        return (jsonify({'success': True, 'token': new_user.token()}), 200)
    else:
        abort(403)

@app.route('/api/login', methods=['POST'])
def login():
    email = request.form['email']
    password = request.form['password']

    user = User.login(email=email, password=password)

    if user:
        login_user(user)
        return (jsonify({'success': True, 'token': user.token()}), 200)
    else:
        abort(403)

@app.route('/api/logout')
def logout():
    logout_user()
    return (jsonify({'success': True}), 200)

# Synchronization

@app.route('/api/sync', methods=['POST'])
@token_required
def sync_user(current_user):
    if not current_user.is_authenticated:
        abort(403)

    return "TODO"

# Game Management

@app.route('/api/game/create', methods=['POST'])
@token_required
def create_game(current_user):
    if not current_user.is_authenticated:
        abort(403)

    user_emails = request.form.get('users')
    if user_emails is None:
        abort(400)

    user_emails = user_emails.split(';')
    if len(user_emails) < 1 or len(user_emails) > 5:
        abort(400)

    users = []
    for user_email in user_emails:
        user = User.get_or_none(User.email == user_email)
        if user is None:
            abort(400)
        else:
            users.append(user)

    game = Game.create()
    UserGame.create(current_user, game, UserRole.OWNER)

    for user in users:
        UserGame.create(user, game, UserRole.PLAYER)

    return (jsonify({'success': True, 'game_id': game.id}), 200)

@app.route('/api/game/accept', methods=['POST'])
@token_required
def accept_game_invite(current_user):
    if not current_user.is_authenticated:
        abort(403)

    game_id = request.form.get('game')
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

    return (jsonify({'success': True}), 200)

@app.route('/api/game/add_action', methods=['POST'])
@token_required
def add_action_to_game(current_user):
    if not current_user.is_authenticated:
        abort(403)

    return "TODO"

#
# Main
#

if __name__ == '__main__':
    app.run(debug=True)
