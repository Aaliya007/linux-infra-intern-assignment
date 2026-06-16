from http.server import BaseHTTPRequestHandler, HTTPServer
import json
import os

PORT = int(os.getenv("PORT", 8080))

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/health":
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()

            response = {
                "status": "ok"
            }

            self.wfile.write(
                json.dumps(response).encode()
            )

        else:
            self.send_response(404)
            self.end_headers()

server = HTTPServer(("0.0.0.0", PORT), Handler)

print(f"Server running on port {PORT}")

server.serve_forever()

