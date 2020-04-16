import datetime

import flask
import flask_cors
import flask_login
import itsdangerous

import engine
import secrets

from models import db
from models import User
from models import Game
from models import UserGame
from models import Action

#
# Setup
#

app = flask.Flask(__name__)
app.secret_key = secrets.app_secrets["secret_key"]

flask_cors.CORS(app)

#
# Flask-Login
#

login_manager = flask_login.LoginManager()
login_manager.init_app(app)
login_manager.login_view = "login"

@login_manager.user_loader
def load_user(user_id):
    return User.get_or_none(User.email == user_id)

#
# Token Authentication
#

def token_required(function):
    def wrapper(*args, **kwargs):
        api_token = flask.request.headers.get("X-App-Token")

        if not api_token:
            return error("No API token found in request", 400)

        try:
            signer = itsdangerous.Signer(secrets.app_secrets["token_signing_key"])
            email = signer.unsign(api_token).decode("utf-8")

            user = User.get(User.email == email)

            kwargs["current_user"] = user
            flask_login.login_user(user)
        except Exception as e:
            print("Error logging user in with token: " + str(e))
            return error("Invalid request", 400)

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
    db.create_tables([
        User,
        Game,
        UserGame,
        Action
    ], safe=True)

#
# Frontend Routes
#

# Account Management

@app.route("/api/signup", methods=["POST"])
def signup():
    body = flask.request.get_json()
    if body is None:
        return error("Could not decode body as JSON", 400)

    name = body.get("name")
    email = body.get("email")
    password = body.get("password")

    existing_user = User.get_or_none(User.email == email)
    if existing_user:
        return error("User already exists", 403)

    new_user = User.create(email, name, password)

    if new_user:
        flask_login.login_user(new_user)
        return success(token=new_user.token())
    else:
        return error("Could not log new user in", 403)

@app.route("/api/login", methods=["POST"])
def login():
    body = flask.request.get_json()
    if body is None:
        return error("Could not decode body as JSON", 400)

    email = body.get("email")
    password = body.get("password")

    user = User.login(email=email, password=password)

    if user:
        flask_login.login_user(user)
        return success(token=user.token())
    else:
        return error("Could not log user in", 403)

@app.route("/api/logout")
def logout():
    flask_login.logout_user()
    return success()

# Synchronization

@app.route("/api/sync", methods=["POST"])
@token_required
def sync_user(current_user):
    if not current_user.is_authenticated:
        return error("User must be authenticated", 403)

    body = flask.request.get_json()
    if body is None:
        return error("Could not decode body as JSON", 400)
    
    last_updated_string = body.get("last_updated")
    if last_updated_string is None:
        return error("Last updated date and time is required", 400)

    try:
        last_updated = datetime.datetime.fromisoformat(last_updated_string)
        if last_updated.tzinfo is None:
            raise ValueError
    except ValueError:
        return error("Invalid last updated date and time", 400)

    games = Game.select().where(Game.last_updated > last_updated)
    usergames = UserGame.select().where(UserGame.game.in_(games))
    actions = Action.select().where(Action.game.in_(games) & (Action.created > last_updated))

    # TODO: This is gross and I'm sure there's a better way to do this directly
    #       in a database query
    user_ids = []
    for usergame in usergames:
        if usergame.user_id not in user_ids:
            user_ids.append(usergame.user_id)

    users = User.select().where(User.id.in_(user_ids) & (User.last_updated > last_updated))

    return success(
        games=[game.to_json() for game in games],
        usergames=[usergame.to_json() for usergame in usergames],
        actions=[action.to_json() for action in actions],
        users=[user.to_json() for user in users]
    )

# Game Management

@app.route("/api/game/create", methods=["POST"])
@token_required
def create_game(current_user):
    if not current_user.is_authenticated:
        return error("User must be authenticated", 403)

    body = flask.request.get_json()
    if body is None:
        return error("Could not decode body as JSON", 400)

    user_emails = body.get("users")
    if (user_emails is None) or (type(user_emails) is not list):
        return error("Emails of other players required", 400)

    if len(user_emails) < 1 or len(user_emails) > 5:
        return error("Player count is out of range", 400)

    users = []
    for user_email in user_emails:
        user = User.get_or_none(User.email == user_email)
        if user is None:
            return error("Unknown user", 400)
        else:
            users.append(user)

    game = Game.create(users)
    UserGame.create(current_user, game, UserRole.OWNER)

    for user in users:
        UserGame.create(user, game, UserRole.PLAYER)

    return success(game_id=game.id)

@app.route("/api/game/accept", methods=["POST"])
@token_required
def accept_game_invite(current_user):
    if not current_user.is_authenticated:
        return error("User must be authenticated", 403)

    body = flask.request.get_json()
    if body is None:
        return error("Could not decode body as JSON", 400)

    game_id = body.get("game")
    if game_id is None:
        return error("Game required", 400)

    game = Game.get_or_none(Game.id == game_id)
    if game is None:
        return error("Unknown game", 400)

    usergame = UserGame.get_or_none(UserGame.user == current_user, UserGame.game == game)
    if usergame is None:
        return error("User is not a part of this game", 400)

    usergame.user_accepted = True
    usergame.save()

    game.last_updated = datetime.datetime.now()
    game.save()

    return success()

@app.route("/api/game/add_action", methods=["POST"])
@token_required
def add_action_to_game(current_user):
    if not current_user.is_authenticated:
        return error("User must be authenticated", 403)

    body = flask.request.get_json()
    if body is None:
        return error("Could not decode body as JSON", 400)

    game_id = body.get("game")
    if game_id is None:
        return error("Game required", 400)

    game = Game.get_or_none(Game.id == game_id)
    if game is None:
        return error("Unknown game", 400)

    if not game.have_all_players_accepted_invite:
        return error("Players have not all accepted invites yet", 400)

    action_json = body.get("action")
    if action_json is None:
        return error("Action required", 400)

    action = Action.create_without_saving(action_json, game)

    if not action.content_has_player:
        return error("Invalid action", 400)

    if not action.is_for_player(current_user.email):
        return error("Cannot play for another player", 400)

    try:
        game.load_initial_state()
        game.load_actions()
    except (engine.IllegalActionError, engine.IllegalSetupError) as e:
        return error("Error loading game: " + str(e), 400)

    try:
        game.apply_action(action)
    except (engine.IllegalActionError, engine.IllegalSetupError) as e:
        return error("Error applying new action: " + str(e), 400)

    action.save()

    game.last_updated = datetime.datetime.now()
    game.save()

    return success()

#
# Helpers
#

def error(message, code):
    return (flask.jsonify({"success": False, "message": message}), code)

def success(*args, **kwargs):
    response_json = {"success": True}

    for (key, value) in kwargs.items():
        response_json[key] = value

    return (flask.jsonify(response_json), 200)

#
# Main
#

if __name__ == "__main__":
    app.run(debug=True)
