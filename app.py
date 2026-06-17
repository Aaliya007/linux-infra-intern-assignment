#!/usr/bin/env python3
from http.server import BaseHTTPRequestHandler, HTTPServer
from socketserver import ThreadingMixIn
from datetime import datetime, timezone
import json
import logging
import os
import signal
import sys


APP_NAME = "infra-demo"
HEALTH_ENDPOINT = "/health"
HOST = os.getenv("HOST", "0.0.0.0")
PORT = int(os.getenv("PORT", "8080"))
LOG_DIR = os.getenv("LOG_DIR", "/var/log/infra-demo")
LOG_FILE = os.path.join(LOG_DIR, "app.log")
START_TIME = datetime.now(timezone.utc)

server = None


def setup_logging() -> logging.Logger:
    os.makedirs(LOG_DIR, exist_ok=True)

    logger = logging.getLogger(APP_NAME)
    logger.setLevel(logging.INFO)
    logger.handlers.clear()

    formatter = logging.Formatter(
        fmt="%(asctime)s %(levelname)s %(message)s",
        datefmt="%Y-%m-%dT%H:%M:%S%z",
    )

    file_handler = logging.FileHandler(LOG_FILE)
    file_handler.setFormatter(formatter)

    stream_handler = logging.StreamHandler(sys.stdout)
    stream_handler.setFormatter(formatter)

    logger.addHandler(file_handler)
    logger.addHandler(stream_handler)
    logger.propagate = False
    return logger


logger = setup_logging()


class ThreadedHTTPServer(ThreadingMixIn, HTTPServer):
    daemon_threads = True
    allow_reuse_address = True


class Handler(BaseHTTPRequestHandler):
    server_version = "InfraDemo/1.0"
    sys_version = ""

    def _send_json(self, status_code: int, payload: dict) -> None:
        body = json.dumps(payload).encode("utf-8")
        self.send_response(status_code)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Cache-Control", "no-store")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, fmt: str, *args) -> None:
        logger.info(
            '%s - - [%s] %s',
            self.client_address[0],
            self.log_date_time_string(),
            fmt % args,
        )

    def do_GET(self):
        if self.path == HEALTH_ENDPOINT:
            payload = {
                "status": "ok",
                "service": APP_NAME,
                "timestamp": datetime.now(timezone.utc).isoformat(),
                "port": PORT,
                "uptime_seconds": int(
                    (datetime.now(timezone.utc) - START_TIME).total_seconds()
                ),
            }
            self._send_json(200, payload)
            return

        if self.path in ("/", ""):
            payload = {
                "message": "infra-demo service is running",
                "health_endpoint": HEALTH_ENDPOINT,
            }
            self._send_json(200, payload)
            return

        self._send_json(
            404,
            {
                "status": "not_found",
                "path": self.path,
            },
        )

    def do_POST(self):
        self.send_response(405)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Cache-Control", "no-store")
        self.send_header("Allow", "GET")
        body = json.dumps(
            {
                "status": "method_not_allowed",
            }
        ).encode("utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)


def shutdown_handler(signum, frame):
    logger.info("Shutdown signal received")
    if server:
        server.shutdown()


def main():
    global server
    try:
        server = ThreadedHTTPServer((HOST, PORT), Handler)

        signal.signal(signal.SIGTERM, shutdown_handler)
        signal.signal(signal.SIGINT, shutdown_handler)

        logger.info(
            "%s starting on http://%s:%s",
            APP_NAME,
            HOST,
            PORT,
        )
        server.serve_forever()
    except KeyboardInterrupt:
        logger.info("Shutdown requested by keyboard interrupt")
    except OSError as exc:
        logger.exception("Unable to start server: %s", exc)
        raise
    except Exception as exc:
        logger.exception("Fatal server error: %s", exc)
        raise
    finally:
        if server:
            logger.info("%s stopping", APP_NAME)
            server.server_close()


if __name__ == "__main__":
    main()