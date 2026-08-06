import unittest

from wordcount import stats


class StatsTest(unittest.TestCase):
    def test_basic(self):
        result = stats("one two\nthree\n")
        self.assertEqual(result["lines"], 2)
        self.assertEqual(result["words"], 3)

    def test_empty_file(self):
        result = stats("")
        self.assertEqual(result["lines"], 0)
        self.assertEqual(result["words"], 0)
        self.assertEqual(result["words_per_line"], 0)


if __name__ == "__main__":
    unittest.main()
