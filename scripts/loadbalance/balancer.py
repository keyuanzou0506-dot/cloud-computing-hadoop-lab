#!/usr/bin/env python3
"""Educational round-robin HTTP load balancer with per-request failure checks."""
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from threading import Lock
from urllib.request import urlopen
from urllib.error import HTTPError, URLError
import socket

BACKENDS = (("A", 8101), ("B", 8102), ("C", 8103))
next_index = 0
index_lock = Lock()

def fetch_backend(port):
    try:
        with urlopen(f"http://127.0.0.1:{port}/", timeout=0.6) as response:
            if response.status == 200:
                return response.read()
    except (HTTPError, URLError, TimeoutError, OSError, socket.timeout):
        pass
    return None

class Handler(BaseHTTPRequestHandler):
    def respond(self, status, body):
        self.send_response(status)
        self.send_header("Content-Type", "text/plain; charset=utf-8")
        self.send_header("Cache-Control", "no-store")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        global next_index
        if self.path.split("?", 1)[0] == "/health":
            return self.respond(200, b"Load balancer OK\n")
        if self.path.split("?", 1)[0] != "/":
            return self.respond(404, b"Not Found\n")
        with index_lock:
            start = next_index
            next_index = (next_index + 1) % len(BACKENDS)
        for offset in range(len(BACKENDS)):
            name, port = BACKENDS[(start + offset) % len(BACKENDS)]
            body = fetch_backend(port)
            if body is not None:
                return self.respond(200, body)
        self.respond(503, b"No healthy backend available\n")

    def log_message(self, format, *values):
        pass

if __name__ == "__main__":
    print("Round-robin load balancer: listening on 0.0.0.0:8080", flush=True)
    ThreadingHTTPServer(("0.0.0.0", 8080), Handler).serve_forever()
