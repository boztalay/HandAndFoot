import datetime
import enum
import json

import flask_login
import itsdangerous
import peewee
import werkzeug

import engine
import sekrits

db = peewee.MySQLDatabase(
    sekrits.db_secrets["name"],
    host=sekrits.db_secrets["host"],
    user=sekrits.db_secrets["user"],
    passwd=sekrits.db_secrets["password"],
    charset="utf8mb4" # Enable unicode
)

class UserRole(enum.Enum):
    OWNER = "owner"
    PLAYER = "player"

class BaseModel(peewee.Model):
    class Meta:
        database = db

class User(BaseModel, flask_login.UserMixin):
    first_name = peewee.CharField()
    last_name = peewee.CharField()
    email = peewee.CharField(unique=True)
    password_hash = peewee.CharField()
    created = peewee.DateTimeField(default=datetime.datetime.now)
    last_updated = peewee.DateTimeField(default=datetime.datetime.now)

    @staticmethod
    def login(email, password):
        try:
            user = User.get(User.email == email)
            if user.check_password(password):
                return user
            else:
                return None
        except Exception as e:
            print(e)
            return None

    @staticmethod
    def create(email, first_name, last_name, password):
        password_hash = werkzeug.security.generate_password_hash(password)
        user = User(email=email, first_name=first_name, last_name=last_name, password_hash=password_hash)
        user.save()
        return user

    def check_password(self, password):
        return werkzeug.security.check_password_hash(self.password_hash, password)

    def get_id(self):
        return self.email

    @property
    def is_active(self):
        return True

    @property
    def is_authenticated(self):
        return True

    @property
    def is_anonymous(self):
        # Don't support anonymous users
        return False

    def token(self):
        signer = itsdangerous.Signer(sekrits.app_secrets["token_signing_key"])
        token = signer.sign(self.email)
        return token.decode('utf-8')

    def to_json(self):
        return {
            "id": self.id,
            "first_name": self.first_name,
            "last_name": self.last_name,
            "email": self.email,
            "created": self.created,
            "last_updated": self.last_updated
        }

class Game(BaseModel):
    initial_state = peewee.TextField()
    title = peewee.CharField()
    current_user = peewee.ForeignKeyField(User, lazy_load=False)
    created = peewee.DateTimeField(default=datetime.datetime.now)
    last_updated = peewee.DateTimeField(default=datetime.datetime.now)

    @staticmethod
    def create(title, users):
        player_names = [user.email for user in users]
        game_engine = engine.Engine(player_names)

        initial_game_state_json = game_engine.generate_initial_game_state()
        initial_game_state_string = json.dumps(initial_game_state_json)

        game = Game(title=title, initial_state=initial_game_state_string, current_user=users[0])
        game.save()

        return game

    @property
    def usergames(self):
        return UserGame.select().where(UserGame.game == self.id).order_by(UserGame.id)

    @property
    def have_all_players_accepted_invite(self):
        return (len([usergame for usergame in self.usergames if not usergame.user_accepted]) == 0)

    def load_initial_state(self):
        player_names = [usergame.fetch_user().email for usergame in self.usergames]
        self.game_engine = engine.Engine(player_names)

        initial_game_state_json = json.loads(self.initial_state)
        self.game_engine.start_game_with_initial_state(initial_game_state_json)

    def load_actions(self):
        actions = Action.select().where(Action.game == self).order_by(Action.created)

        for action in actions:
            self.apply_action(action)

    def apply_action(self, action):
        self.game_engine.apply_action(action.load_content_json())

    def update_current_user(self):
        current_user_email = self.game_engine.current_player.name
        current_user = User.get_or_none(User.email == current_user_email)
        if current_user is None:
            raise ValueError("Something went terribly wrong")

        self.current_user = current_user

    def to_json(self):
        return {
            "id": self.id,
            "initial_state": self.initial_state,
            "title": self.title,
            "current_user": self.current_user_id,
            "created": self.created,
            "last_updated": self.last_updated
        }

class UserGame(BaseModel):
    user = peewee.ForeignKeyField(User, lazy_load=False)
    game = peewee.ForeignKeyField(Game, lazy_load=False)
    role = peewee.CharField()
    user_accepted = peewee.BooleanField(default=False)

    @staticmethod
    def create(user, game, role):
        usergame = UserGame(user=user, game=game, role=role.value)

        if role == UserRole.OWNER:
            usergame.user_accepted = True

        usergame.save()
        return user

    def fetch_user(self):
        return User.get(User.id == self.user)

    def to_json(self):
        return {
            "id": self.id,
            "user": self.user_id,
            "game": self.game_id,
            "role": self.role,
            "user_accepted": self.user_accepted
        }

class Action(BaseModel):
    content = peewee.TextField()
    game = peewee.ForeignKeyField(Game, lazy_load=False)
    created = peewee.DateTimeField(default=datetime.datetime.now)

    @staticmethod
    def create_without_saving(content_json, game):
        content = json.dumps(content_json)
        action = Action(content=content, game=game)
        action.content_json = content_json
        return action

    def load_content_json(self):
        self.content_json = json.loads(self.content)
        return self.content_json

    @property
    def content_has_player(self):
        # NOTE: Requires that either create_without_saving or load_content_json
        #       has been called
        return ("player" in self.content_json)

    def is_for_player(self, player_name):
        # NOTE: Requires that either create_without_saving or load_content_json
        #       has been called
        return (self.content_json["player"] == player_name)

    def to_json(self):
        return {
            "id": self.id,
            "content": self.content,
            "game": self.game_id,
            "created": self.created
        }
