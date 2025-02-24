import socket
import structlog


logger = structlog.get_logger()

redis_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
redis_socket.connect(('localhost', 6379))

redis_socket.sendall(b"SET name harsha\r\n")
set_response = redis_socket.recv(1024).decode()
logger.info(set_response)

redis_socket.sendall(b"GET name\r\n")
get_response = redis_socket.recv(1024).decode()
logger.info(get_response)

redis_socket.close()
