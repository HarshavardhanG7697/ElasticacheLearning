import redis
import structlog
import json

logger = structlog.get_logger()

conn = redis.Redis(
    host="localhost",
    decode_responses=True,
)

keys_added = conn.info("keyspace")
logger.info(json.dumps(keys_added, indent=4, default=str))
