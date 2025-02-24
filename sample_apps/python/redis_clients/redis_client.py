import redis
import structlog

logger = structlog.get_logger()

connection = redis.Redis(host="localhost", port=6379, decode_responses=True)

logger.info(connection.set("name", "harsha"))
logger.info(connection.get("name"))