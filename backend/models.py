from datetime import datetime
import enum
import json
import yaml

from flask_login import UserMixin
from flask_login import LoginManager, login_user, logout_user, login_required

from peewee import *

from itsdangerous import Signer
from werkzeug.security import generate_password_hash, check_password_hash

secrets = yaml.load(open('./secrets.yaml'))

app_secrets = secrets['app']
TOKEN_SIGNING_KEY = app_secrets['token_signing_key']

db_secrets = secrets['database']
db_name = db_secrets['name']
db_host = db_secrets['host']
db_user = db_secrets['user']
db_password = db_secrets['password']

db = MySQLDatabase(
    db_name,
    host=db_host,
    user=db_user,
    passwd=db_password,
    charset='utf8mb4' # Enable unicode
)

class UserRole(enum.Enum):
    OWNER = "owner"
    PLAYER = "player"

class BaseModel(Model):
    class Meta:
        database = db

class User(BaseModel, UserMixin):
    name = CharField()
    email = CharField(unique=True)
    password_hash = CharField()
    created = DateTimeField(default=datetime.now)
    last_updated = DateTimeField(default=datetime.now)

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
        password_hash = generate_password_hash(password)
        user = User(email=email, name=name, password_hash=password_hash)
        user.save()
        return user

    def check_password(self, password):
        return check_password_hash(self.password_hash, password)

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
        s = Signer(TOKEN_SIGNING_KEY)
        token = s.sign(self.email)
        return token.decode('utf-8')

class Game(BaseModel):
    created = DateTimeField(default=datetime.now)
    last_updated = DateTimeField(default=datetime.now)

    @property
    def usergames(self):
        return UserGame.select().where(UserGame.game == self.id)

    @property
    def have_all_players_accepted_invite(self):
        return (len([usergame for usergame in self.usergames if not usergame.user_accepted]) == 0)

class UserGame(BaseModel):
    user = ForeignKeyField(User)
    game = ForeignKeyField(Game)
    role = CharField()
    user_accepted = BooleanField(default=False)

    @staticmethod
    def create(user, game, role):
        usergame = UserGame(user=user, game=game, role=role.value)

        if role == UserRole.OWNER:
            usergame.user_accepted = True

        usergame.save()
        return user

class Action(BaseModel):
    action_type = CharField()
    content = CharField()
    game = ForeignKeyField(Game)
    created = DateTimeField(default=datetime.now)
