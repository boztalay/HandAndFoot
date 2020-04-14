import datetime
import enum
import json

import flask_login
import itsdangerous
import peewee
import werkzeug

import engine
import secrets

db = peewee.MySQLDatabase(
    secrets.db_secrets["name"],
    host=secrets.db_secrets["host"],
    user=secrets.db_secrets["user"],
    passwd=secrets.db_secrets["password"],
    charset="utf8mb4" # Enable unicode
)

class UserRole(enum.Enum):
    OWNER = "owner"
    PLAYER = "player"

class BaseModel(peewee.Model):
    class Meta:
        database = db

class User(BaseModel, flask_login.UserMixin):
    name = peewee.CharField()
    email = peewee.CharField(unique=True)
    password_hash = peewee.CharField()
    created = peewee.DateTimeField(default=datetime.datetime.now)
    last_updated = peewee.DateTimeField(default=datetime.datetime.now)

    def to_dict(self):    
        return {
            'id': self.id,
            'name': self.name,
            'email': self.email,
        }

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
    def create(email, name, password):
        password_hash = werkzeug.security.generate_password_hash(password)
        user = User(email=email, name=name, password_hash=password_hash)
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
        signer = itsdangerous.Signer(secrets.app_secrets["token_signing_key"])
        token = signer.sign(self.email)
        return token.decode('utf-8')

class Game(BaseModel):
    initial_state = peewee.TextField()
    created = peewee.DateTimeField(default=datetime.datetime.now)
    last_updated = peewee.DateTimeField(default=datetime.datetime.now)

    @staticmethod
    def create(player_count):
        initial_game_state = engine.generate_initial_game_state(player_count)
        initial_game_state_json = json.dumps(initial_game_state)

        game = Game(initial_state=initial_game_state_json)
        game.save()

        return game

    @property
    def usergames(self):
        return UserGame.select().where(UserGame.game == self.id)

    @property
    def have_all_players_accepted_invite(self):
        return (len([usergame for usergame in self.usergames if not usergame.user_accepted]) == 0)

    def load_initial_state(self):
        initial_game_state = json.loads(self.initial_state)
        player_names = [usergame.user.email for usergame in self.usergames]
        self.game = engine.create_game_with_initial_state(player_names, initial_game_state)

    def load_actions(self):
        actions = Action.select().where(Action.game == self).order_by(Action.created)

        for action in actions:
            self.apply_action(action)

    def apply_action(self, action):
        self.game.apply_action(action.game_action)

class UserGame(BaseModel):
    user = peewee.ForeignKeyField(User)
    game = peewee.ForeignKeyField(Game)
    role = peewee.CharField()
    user_accepted = peewee.BooleanField(default=False)

    @staticmethod
    def create(user, game, role):
        usergame = UserGame(user=user, game=game, role=role.value)

        if role == UserRole.OWNER:
            usergame.user_accepted = True

        usergame.save()
        return user

class Action(BaseModel):
    content = peewee.TextField()
    game = peewee.ForeignKeyField(Game)
    created = peewee.DateTimeField(default=datetime.datetime.now)

    @staticmethod
    def create(content, game):
        action = Action(content=content, game=game)
        action.load_content_json()

    def load_content_json(self):
        self.content_json = json.loads(self.content)

    @property
    def game_action(self):
        return engine.Action.from_json(self.content_json)
