from http.server import BaseHTTPRequestHandler, HTTPServer

class SimpleHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path in ['/', 'health', '/health_check']:
            self.send_response(200)
            self.end_headers()
            self.wfile.write(b'OK')
        else:
            self.send_response(404)
            self.end_headers()

httpd = HTTPServer(('', 443), SimpleHandler)

print("Serving on port 443...")

httpd.serve_forever()