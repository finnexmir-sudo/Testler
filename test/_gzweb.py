#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Sikislenmis statik server - GitHub Pages kimi.  Olcme ucun."""
import gzip, io, os, sys
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
class H(SimpleHTTPRequestHandler):
    def log_message(self, *a): pass
    def end_headers(self):
        SimpleHTTPRequestHandler.end_headers(self)
    def send_head(self):
        path = self.translate_path(self.path.split("?")[0])
        if os.path.isdir(path): path = os.path.join(path, "index.html")
        if not os.path.isfile(path): return SimpleHTTPRequestHandler.send_head(self)
        ctype = self.guess_type(path)
        data = open(path, "rb").read()
        ae = self.headers.get("Accept-Encoding", "")
        gz = "gzip" in ae and os.path.splitext(path)[1] in (".js", ".css", ".html", ".json", ".svg")
        if gz: data = gzip.compress(data, 6)
        self.send_response(200)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(data)))
        if gz: self.send_header("Content-Encoding", "gzip")
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        return io.BytesIO(data)
ThreadingHTTPServer(("127.0.0.1", int(sys.argv[1])), H).serve_forever()
