# flask-backend-starter

## About

This project is a starter template for a full Python backend. 

It supports a bunch of stuff, including:
* connecting to a database
* creating tables
* creating and authenticating users
* hashing passwords properly
* managing secrets
* allowing login and signup via a web URL
* deploying via Structure

# Configuration
1. Create a virtual environment and activate it
	
`virtualenv -p python3 env`
`. env/bin/activate`

2. Install dependencies

`pip3 install -r requirements.txt`

3. Create and configure `secrets.yaml`

`touch secrets.yaml`

Example:

```yaml
database:
  name: 'appdb'
  host: '127.0.0.1'
  user: 'admin'
  password: 'password'

app:
  secret_key: 'somelongsequenceofrandomcharacters'
```

4. Create the database tables

```bash
python3
```

```python
Python 3.6.5 (default, Apr 25 2018, 14:26:36)
[GCC 4.2.1 Compatible Apple LLVM 9.0.0 (clang-900.0.39.2)] on darwin

>>> from app import *
>>> create_tables()
```

5. Start the application

`python3 app.py`

Visit the following URLs:
* [Signup](localhost:5000/signup)
* [Login](localhost:5000/login)
* [Logout](localhost:5000/logout)

5. Deploy!

`structure deploy my-flask-app`