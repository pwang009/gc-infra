import json
import unittest

from application import application


class TestApp(unittest.TestCase):
    def call(self, path="/"):
        environ = {
            "REQUEST_METHOD": "GET",
            "PATH_INFO": path,
            "QUERY_STRING": "name=Tony",
            "wsgi.input": None,
        }
        status = {}
        headers = {}

        def start_response(status_text, response_headers):
            status["text"] = status_text
            headers["list"] = response_headers

        body = b"".join(application(environ, start_response))
        return status["text"], headers["list"], json.loads(body.decode("utf-8"))

    def test_root_endpoint(self):
        status, headers, payload = self.call("/")
        self.assertEqual(status, "200 OK")
        self.assertTrue(any(name == "Content-Type" and value == "application/json" for name, value in headers))
        self.assertEqual(payload["message"], "Elastic Beanstalk test API is working")

    def test_health_endpoint(self):
        status, _, payload = self.call("/health")
        self.assertEqual(status, "200 OK")
        self.assertEqual(payload["status"], "ok")

    def test_not_found(self):
        status, _, payload = self.call("/missing")
        self.assertEqual(status, "404 Not Found")
        self.assertEqual(payload["error"], "Not Found")


if __name__ == "__main__":
    unittest.main()
