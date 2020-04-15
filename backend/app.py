import flask
import flask_cors
import flask_login
import itsdangerous

import engine
import models
import secrets

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
    return models.User.get_or_none(models.User.email == user_id)

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

            user = models.User.get(models.User.email == email)

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
    if models.db.is_closed():
        models.db.connect()

@app.teardown_request
def _db_close(exc):
    if not models.db.is_closed():
        models.db.close()

#
# Testing
#

def create_tables():
    models.db.create_tables([
        models.User,
        models.Game,
        models.UserGame,
        models.Action
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

    existing_user = models.User.get_or_none(models.User.email == email)
    if existing_user:
        return error("User already exists", 403)

    new_user = models.User.create(email, name, password)

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

    user = models.User.login(email=email, password=password)

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

    return error("Not implemented", 500)

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
        user = models.User.get_or_none(models.User.email == user_email)
        if user is None:
            return error("Unknown user", 400)
        else:
            users.append(user)

    game = models.Game.create(users)
    models.UserGame.create(current_user, game, models.UserRole.OWNER)

    for user in users:
        models.UserGame.create(user, game, models.UserRole.PLAYER)

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

    game = models.Game.get_or_none(models.Game.id == game_id)
    if game is None:
        return error("Unknown game", 400)

    usergame = models.UserGame.get_or_none(models.UserGame.user == current_user, models.UserGame.game == game)
    if usergame is None:
        return error("User is not a part of this game", 400)

    usergame.user_accepted = True
    usergame.save()

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

    game = models.Game.get_or_none(models.Game.id == game_id)
    if game is None:
        return error("Unknown game", 400)

    if not game.have_all_players_accepted_invite:
        return error("Players have not all accepted invites yet", 400)

    action_json = body.get("action")
    if action_json is None:
        return error("Action required", 400)

    action = models.Action.create_without_saving(action_json, game)

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
