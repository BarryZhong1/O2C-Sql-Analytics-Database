#!/usr/bin/env python3
"""Bridge port 8000 from a Codespaces devcontainer to Docker host's FastAPI.

Docker-outside-of-docker runs Compose services beside the workspace container,
so a published host port need not be reachable through Codespaces forwarding.
This bridge runs IN the workspace container and shows startup progress instead
of a browser 502 until the API becomes available.
"""
import http.client
import json
import os
import socket
import struct
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

PORT = int(os.getenv("O2C_BRIDGE_PORT", "8000"))
BACKEND_PORT = int(os.getenv("O2C_BACKEND_PORT", "8000"))
IGNORE = {"connection", "proxy-connection", "keep-alive", "transfer-encoding",
          "upgrade", "te", "trailer", "proxy-authenticate", "proxy-authorization"}
START_PAGE = b'''<!doctype html><html><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<meta http-equiv="refresh" content="8"><title>O2C Agent is starting</title></head>
<body style="background:#0b1424;color:#eff6ff;font:16px system-ui;max-width:760px;margin:12vh auto;padding:25px">
<h1>Preparing the O2C Process Improvement Agent</h1>
<p>The Codespace is connected. MySQL and the API may still be loading.
This page refreshes automatically every eight seconds.</p>
<p>Check Codespaces terminal:</p>
<pre style="padding:15px;border:1px solid #375274;border-radius:9px">
tail -n 60 "$HOME/.local/state/o2c-demo/bootstrap.log"
</pre>
<p>If setup fails, run <code>bash .devcontainer/bootstrap.sh</code>.</p>
</body></html>'''


def docker_host_candidates():
    hosts = []
    explicit = os.getenv("O2C_BACKEND_HOST")
    if explicit:
        hosts.append(explicit)
    try:
        for entry in socket.getaddrinfo("host.docker.internal", None, type=socket.SOCK_STREAM):
            hosts.append(entry[4][0])
    except OSError:
        pass
    try:
        with open("/proc/net/route", encoding="ascii") as routes:
            for line in routes:
                row = line.split()
                if len(row) > 2 and row[1] == "00000000":
                    hosts.append(socket.inet_ntoa(struct.pack("<L", int(row[2], 16))))
    except (OSError, ValueError):
        pass
    hosts.append("172.17.0.1")
    return list(dict.fromkeys(h for h in hosts if h not in ("127.0.0.1", "::1")))


class Handler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def do_GET(self): self.forward()
    def do_HEAD(self): self.forward()
    def do_POST(self): self.forward()
    def do_PUT(self): self.forward()
    def do_DELETE(self): self.forward()
    def do_PATCH(self): self.forward()
    def do_OPTIONS(self): self.forward()

    def respond(self, status, payload, mime):
        self.send_response(status)
        self.send_header("Content-Type", mime)
        self.send_header("Content-Length", str(len(payload)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        if self.command != "HEAD":
            self.wfile.write(payload)

    def forward(self):
        if self.path == "/_codespace_bridge_probe":
            return self.respond(200, b'{"bridge":"ok"}', "application/json")
        try:
            size = int(self.headers.get("Content-Length", "0"))
        except ValueError:
            return self.respond(400, b'{"error":"Invalid length"}', "application/json")
        if not 0 <= size <= 10_000_000:
            return self.respond(413, b'{"error":"Request too large"}', "application/json")
        body = self.rfile.read(size) if size else None
        headers = {k: v for k, v in self.headers.items()
                   if k.lower() not in IGNORE and k.lower() != "host"}
        for host in docker_host_candidates():
            conn = None
            try:
                conn = http.client.HTTPConnection(host, BACKEND_PORT, timeout=5)
                conn.request(self.command, self.path, body=body, headers=headers)
                res = conn.getresponse()
                payload = res.read()
                self.send_response(res.status, res.reason)
                for key, val in res.getheaders():
                    if key.lower() not in IGNORE and key.lower() != "content-length":
                        self.send_header(key, val)
                self.send_header("Content-Length", str(len(payload)))
                self.end_headers()
                if self.command != "HEAD":
                    self.wfile.write(payload)
                return
            except (OSError, http.client.HTTPException):
                pass
            finally:
                if conn is not None:
                    conn.close()
        if self.command == "GET" and self.path in ("/", "/index.html"):
            self.respond(503, START_PAGE, "text/html; charset=utf-8")
        else:
            self.respond(503, json.dumps({"status":"starting","detail":"Agent backend not reachable yet"}).encode(), "application/json")

    def log_message(self, fmt, *args):
        if self.path != "/_codespace_bridge_probe":
            super().log_message(fmt, *args)


if __name__ == "__main__":
    print("[codespace-bridge] Listening on workspace port", PORT,
          "Docker host candidates:", docker_host_candidates(), flush=True)
    ThreadingHTTPServer(("0.0.0.0", PORT), Handler).serve_forever()
