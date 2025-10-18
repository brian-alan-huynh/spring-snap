import os

import boto3
import redis
import json
from dotenv import load_dotenv
from sqlalchemy import create_engine, event
from pymongo import MongoClient

load_dotenv()
env = os.getenv

REGION = env("AWS_REGION")
secretsmanager_client = boto3.client("secretsmanager", region_name=REGION)

def get_secret_string(secret_arn):
    response = secretsmanager_client.get_secret_value(SecretId=secret_arn)
    return json.loads(response["SecretString"])

# RDS
rds_secret_string = get_secret_string(env("AWS_RDS_SECRET_ARN"))

DB_USERNAME = rds_secret_string["username"]
DB_NAME = rds_secret_string["db_name"]
DB_HOST = rds_secret_string["db_host"]
DB_PORT = rds_secret_string["db_port"]

rds_client = boto3.client("rds", region_name=REGION)

def generate_token():
    try:
        token = rds_client.generate_db_auth_token(
            DBHostname=DB_HOST,
            Port=int(DB_PORT),
            DBUsername=DB_USERNAME,
        )
        
        return token
    
    except Exception as e:
        error_message = f"Failed to generate RDS auth token: {e}"
        raise Exception(error_message) from e

connection_url = (
    f"postgresql+psycopg2://{DB_USERNAME}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
    "?sslmode=require"
)

RDS_ENGINE = create_engine(
    connection_url,
    pool_size=25,
    max_overflow=50,
    pool_pre_ping=True,
    pool_recycle=3600,
    connect_args={
        "connect_timeout": 10,
        "application_name": "Curby Storage Backend",
    },
)

@event.listens_for(RDS_ENGINE, "do_connect")
def add_auth_token(dialect, conn_rec, cargs, cparams):
    cparams["password"] = generate_token()

# Redis
redis_secret_string = get_secret_string(env("REDIS_SECRET_ARN"))

REDIS_HOST = redis_secret_string["host"]
REDIS_PORT = int(redis_secret_string["port"])
REDIS_PASSWORD = redis_secret_string["password"]

REDIS_CLIENT = redis.Redis(
    host=REDIS_HOST,
    port=REDIS_PORT,
    username="default",
    password=REDIS_PASSWORD,
    ssl=True,
    ssl_cert_reqs=None,
    ssl_ca_certs=None,
    ssl_keyfile=None,
    decode_responses=True,
    socket_timeout=5,
    socket_connect_timeout=10,
    retry_on_timeout=True,
    socket_keepalive=True,
    health_check_interval=30,
)

# S3
S3_CLIENT = boto3.client(
    "s3",
    region_name=REGION,
    config=boto3.session.Config(signature_version="s3v4"),
)
BUCKET_NAME = env("AWS_S3_BUCKET_NAME")

# MongoDB
mongodb_secret_string = get_secret_string(env("MONGODB_SECRET_ARN"))

MONGO_CLIENT = MongoClient(
    mongodb_secret_string,
    tls=True,
    tlsAllowInvalidCertificates=False,
    socketTimeoutMS=None,
    connectTimeoutMS=10000,
    serverSelectionTimeoutMS=30000,
    maxPoolSize=120,
    retryWrites=True,
    retryReads=True,
)
MONGO_DB = MONGO_CLIENT[env("MONGODB_DB_NAME")]
MONGO_COLLECTION = MONGO_DB[env("MONGODB_DB_COLLECTION_NAME")]

# Confluent Kafka
confluent_kafka_secret_string = get_secret_string(env("KAFKA_SECRET_ARN"))

KAFKA_API_KEY = confluent_kafka_secret_string["key"]
KAFKA_API_SECRET = confluent_kafka_secret_string["secret"]
KAFKA_BOOTSTRAP_SERVERS = env("KAFKA_BOOTSTRAP_SERVERS")
