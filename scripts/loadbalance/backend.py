#!/usr/bin/env python3
"""Minimal dependency-free backend used only for classroom demonstrations."""
import argparse
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

parser = argparse.ArgumentParser()
parser.add_argument("--name", choices=("A", "B", "C"), required=True)
parser.add_argument("--port", type=int, required=True)
args = parser.parse_args()

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        path = self.path.split("?", 1)[0]
        if path == "/health":
            body, status = b"OK\n", 200
        elif path == "/":
            body, status = f"Response from Server {args.name}\n".encode(), 200
        else:
            body, status = b"Not Found\n", 404
        self.send_response(status)
        self.send_header("Content-Type", "text/plain; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, format, *values):
        pass

if __name__ == "__main__":
    print(f"Server {args.name}: listening on 127.0.0.1:{args.port}", flush=True)
    ThreadingHTTPServer(("127.0.0.1", args.port), Handler).serve_forever()
