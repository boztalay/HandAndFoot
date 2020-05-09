import yaml

secrets = yaml.load(open("./secrets.yaml"))
app_secrets = secrets["app"]
db_secrets = secrets["database"]
