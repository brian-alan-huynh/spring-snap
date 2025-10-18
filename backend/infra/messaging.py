import os
import json
import time
from urllib import request

from confluent_kafka import Producer, Consumer
from fastapi import Request
from dotenv import load_dotenv

from config.config import S3_CLIENT, BUCKET_NAME, REDIS_CLIENT, MONGO_COLLECTION, KAFKA_BOOTSTRAP_SERVERS, KAFKA_API_KEY, KAFKA_API_SECRET

class KafkaConsumeError(Exception):
    "Exception for Kafka consume operations"
    pass
class KafkaMessageError(Exception):
    "Exception for Kafka operations"
    pass

class KafkaMessageProcessError(KafkaMessageError):
    "Exception for Kafka message processing operations"
    pass

class KafkaMessageOperationError(KafkaMessageError):
    "Exception for Kafka message operations"
    pass


def _raise_kafka_consume_error(error: Exception) -> None:
    error_message = f"Failed to consume messages to Kafka: {error}"
    raise KafkaConsumeError(error_message) from error

def _raise_kafka_message_error(error: Exception) -> None:
    error_message = f"Error in consumed Kafka message: {error}"
    raise KafkaMessageError(error_message) from error

def _raise_kafka_message_process_error(error: Exception, request: Request) -> None:
    error_message = f"Failed to process Kafka message logic: {error}"
    request.app.state.logger.log_error(error_message)
    raise KafkaMessageProcessError(error_message) from error

def _raise_kafka_message_operation_error(operation: str, request: Request) -> None:
    error_message = f"Invalid Kafka message operation: {operation}"
    request.app.state.logger.log_error(error_message)
    raise KafkaMessageOperationError(error_message)

load_dotenv()
env = os.getenv

kafka_producer = Producer({
    "bootstrap.servers": KAFKA_BOOTSTRAP_SERVERS,
    "queue.buffering.max.messages": 100000,
    "queue.buffering.max.ms": 500,
    "compression.type": "lz4",
    "security.protocol": "SASL_SSL",
    "sasl.mechanisms": "PLAIN",
    "sasl.username": KAFKA_API_KEY,
    "sasl.password": KAFKA_API_SECRET
})

kafka_consumer = Consumer({
    "bootstrap.servers": KAFKA_BOOTSTRAP_SERVERS,
    "group.id": "curby-kafka-group",
    "auto.offset.reset": "earliest",
    "enable.auto.commit": False,
    "security.protocol": "SASL_SSL",
    "sasl.mechanisms": "PLAIN",
    "sasl.username": KAFKA_API_KEY,
    "sasl.password": KAFKA_API_SECRET
})

kafka_consumer.subscribe([
    "curby.s3",
    "curby.redis",
    "curby.mongodb",
])

BATCH_SIZE = 150
REQ_PER_SECOND = 250
SECONDS_PER_BATCH = BATCH_SIZE / REQ_PER_SECOND

stop_event = None

def process_batch(messages: list):
    success_messages = []
    
    for record in messages:
        if record.error():
            _raise_kafka_message_error(record.error())
        
        try:
            message = json.loads(record.value().decode("utf-8"))
            
            operation = message.get("operation")
            request = message.get("request")
            
            try:
                match operation:
                    case "s3.delete_snap":
                        s3_key = message["s3_key"]
                        
                        S3_CLIENT.delete_object(
                            Bucket=BUCKET_NAME,
                            Key=s3_key
                        )
                        
                    case "s3.delete_all_snaps":
                        user_id = message["user_id"]
                                            
                        response = S3_CLIENT.list_objects_v2(Bucket=BUCKET_NAME, Prefix=str(user_id))
                        
                        objects_to_delete = []
                        
                        for object in response["Contents"]:
                            objects_to_delete.append({ "Key": object["Key"] })
                        
                        S3_CLIENT.delete_objects(
                            Bucket=BUCKET_NAME,
                            Delete={ "Objects": objects_to_delete }
                        )
                    
                    case "redis.add_new_session":
                        session_key = message["session_key"]
                        user_id = message["user_id"]
                        thumbnail_file_url = message["thumbnail_file_url"]
                        created_at = message["created_at"]
                        
                        REDIS_CLIENT.hset(session_key, mapping={
                            "user_id": user_id,
                            "thumbnail_file_url": thumbnail_file_url,
                            "created_at": created_at,
                        })
                        
                        REDIS_CLIENT.expire(session_key, 60 * 60 * 24 * 7 * 4 * 6)
                        
                    case "redis.place_thumbnail_file_url":
                        session_key = message["session_key"]
                        thumbnail_file_url = message["thumbnail_file_url"]
                        
                        REDIS_CLIENT.hset(session_key, "thumbnail_file_url", thumbnail_file_url)
                        
                    case "redis.delete_session":
                        session_key = message["session_key"]
                        REDIS_CLIENT.delete(session_key)
                        
                    case "redis.add_otp":
                        otp = message["otp"]
                        email = message["email"]
                        
                        REDIS_CLIENT.setex(key=email, time=900, value=otp)
                        
                    case "mongodb.add_file_tags":
                        user_id = message["user_id"]
                        s3_key = message["s3_key"]
                        tags = message["tags"]
                        caption = message["caption"]
                        created_at = message["created_at"]
                        
                        MONGO_COLLECTION.insert_one({
                            "user_id": user_id,
                            "s3_key": s3_key,
                            "tags": tags,
                            "caption": caption,
                            "created_at": created_at,
                        })
                        
                    case "mongodb.write_file_caption":
                        s3_key = message["s3_key"]
                        caption = message["caption"]
                        
                        MONGO_COLLECTION.update_one(
                            { "s3_key": s3_key },
                            { "$set": { "caption": caption } },
                        )
                        
                    case "mongodb.delete_file_tags_and_captions":
                        s3_key = message["s3_key"]
                        MONGO_COLLECTION.delete_one({ "s3_key": s3_key })
                        
                    case "mongodb.delete_all_user_file_tags_and_captions":
                        user_id = message["user_id"]
                        MONGO_COLLECTION.delete_many({ "user_id": user_id })
                        
                    case _:
                        _raise_kafka_message_operation_error(operation, request)

                success_messages.append(record)
            
            except KafkaMessageOperationError:
                raise

            except Exception as e:
                _raise_kafka_message_process_error(e, request)
        
        except KafkaMessageOperationError:
            raise
        
        except KafkaMessageProcessError:
            raise
        
        except Exception as e:
            _raise_kafka_message_error(e)
            
    return True if success_messages else False

def run_consumer(event):
    global stop_event
    stop_event = event
    
    while not stop_event.is_set():
        try:
            start_time = time.time()
            messages_batch = kafka_consumer.consume(BATCH_SIZE, timeout=1.0)
            
            if not messages_batch:
                time.sleep(0.5)
                continue
            
            processed_batch = process_batch(messages_batch)
            
            if processed_batch:
                kafka_consumer.commit(asynchronous=False)
            
            elapsed_time = time.time() - start_time
            time.sleep(max(0.0, SECONDS_PER_BATCH - elapsed_time))
            
        except KafkaMessageError:
            raise
        
        except Exception as e:
            _raise_kafka_consume_error(e)
