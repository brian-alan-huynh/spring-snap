#!/bin/bash

echo -e "\nInitializing LocalStack\n"

until awslocal s3 ls 2>/dev/null; do
    echo -e "\nWaiting for LocalStack to start\n"
    sleep 2
done

echo -e "\nCreating LocalStack environment variables\n"

awslocal s3 mb s3://curby-dev-snaps || true

awslocal secretsmanager create-secret \
    --name dev-rds-secret \
    --secret-string '{"username":"curby_user","password":"dev_postgres_password","db_name":"curby","db_host":"postgres","db_port":"5432"}' \
    --region us-east-2 || true

awslocal secretsmanager create-secret \
    --name dev-redis-secret \
    --secret-string '{"host":"redis","port":"6379","password":"dev_redis_password"}' \
    --region us-east-2 || true

awslocal secretsmanager create-secret \
    --name dev-mongodb-secret \
    --secret-string 'mongodb://admin:dev_mongodb_password@mongodb:27017/curby?authSource=admin'
    --region us-east-2 || true

awslocal secretsmanager create-secret \
    --name dev-kafka-secret \
    --secret-string '{"key":"dev-key","secret":"dev-secret"}' \
    --region us-east-2 || true

echo -e "\nLocalStack initialization complete\n"
