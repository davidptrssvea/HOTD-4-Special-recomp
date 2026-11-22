import contextlib
import importlib.util
import io
from pathlib import Path
import subprocess
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
from build_support import build_jobs, run


class BuildSupportTests(unittest.TestCase):
    def test_memory_budget(self):
        gib = 1024**3
        self.assertEqual(build_jobs(memory=gib, cpus=32), 1)
        self.assertEqual(build_jobs(memory=5*gib, cpus=32), 2)
        self.assertEqual(build_jobs(memory=64*gib, cpus=32), 8)
        self.assertEqual(build_jobs(memory=64*gib, cpus=2), 2)
        self.assertEqual(build_jobs(3, memory=gib, cpus=32), 3)
        with self.assertRaises(ValueError):
            build_jobs(-1)

    def test_command_exit_and_redirect(self):
        import tempfile
        with tempfile.TemporaryFile() as output:
            run([sys.executable, '-c', "print('generated source')"], stdout=output)
            output.seek(0)
            self.assertEqual(output.read().strip(), b'generated source')
        with self.assertRaises(subprocess.CalledProcessError) as failure:
            run([sys.executable, '-c', 'raise SystemExit(7)'])
        self.assertEqual(failure.exception.returncode, 7)


if __name__ == '__main__':
    unittest.main()
