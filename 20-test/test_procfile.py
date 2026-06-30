import pathlib
import unittest


class TestProcfile(unittest.TestCase):
    def test_procfile_exists_and_targets_the_wsgi_app(self):
        procfile = pathlib.Path(__file__).with_name("Procfile")
        self.assertTrue(procfile.exists(), "Procfile should be present for Elastic Beanstalk")

        content = procfile.read_text(encoding="utf-8")
        self.assertIn("application:application", content)
        self.assertIn("PORT", content)


if __name__ == "__main__":
    unittest.main()
