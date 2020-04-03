from datetime import datetime
import yaml
import json

from flask_login import UserMixin
from flask_login import LoginManager, login_user, logout_user, login_required

from peewee import *
from werkzeug.security import generate_password_hash, check_password_hash


secrets = yaml.load(open('./secrets.yaml'))
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


class BaseModel(Model):
    class Meta:
        database = db


class User(BaseModel, UserMixin):
    name = CharField()
    email = CharField(unique=True)
    password_hash = CharField()
    created = DateTimeField(default=datetime.now)

    def to_dict(self):    
        return {
            'id': self.id,
            'name': self.name,
            'email': self.email,
        }

    @staticmethod
    def login(email, password):
        try:
            u = User.get(User.email == email)
            if u.check_password(password):
                return u
            else:
                return None
        except Exception as e:
            print(e)
            return None

    @staticmethod
    def create(email, name, password):
        password_hash = generate_password_hash(password)
        u = User(email=email, name=name, password_hash=password_hash)
        u.save()
        return u

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

