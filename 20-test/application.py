import json
import os
import sys
from urllib.parse import parse_qs


def application(environ, start_response):
    path = environ.get("PATH_INFO", "/")
    method = environ.get("REQUEST_METHOD", "GET")
    query_string = environ.get("QUERY_STRING", "")
    query_params = parse_qs(query_string)

    if path == "/health":
        payload = {
            "status": "ok",
            "service": "gc-dev-api",
            "method": method,
        }
        status = "200 OK"
    elif path == "/":
        payload = {
            "message": "Elastic Beanstalk test API is working",
            "service": "gc-dev-api",
            "method": method,
            "query": query_params,
            "port": os.environ.get("PORT", "8000"),
            "python_version": sys.version.split()[0],
        }
        status = "200 OK"
    else:
        payload = {"error": "Not Found", "path": path}
        status = "404 Not Found"

    body = json.dumps(payload, indent=2).encode("utf-8")
    headers = [
        ("Content-Type", "application/json"),
        ("Content-Length", str(len(body))),
    ]
    start_response(status, headers)
    return [body]


if __name__ == "__main__":
    from wsgiref.simple_server import make_server

    port = int(os.environ.get("PORT", "8000"))
    print(f"Starting test API on port {port}")
    make_server("0.0.0.0", port, application).serve_forever()
