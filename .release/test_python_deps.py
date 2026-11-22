import contextlib
import hashlib
import importlib.util
import io
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch
import zipfile

spec = importlib.util.spec_from_file_location('python_deps', Path(__file__).resolve().parents[1] / 'tools/python_deps.py')
deps = importlib.util.module_from_spec(spec)
spec.loader.exec_module(deps)


def fixture(extra=None):
    buffer = io.BytesIO()
    with zipfile.ZipFile(buffer, 'w') as archive:
        archive.writestr('elftools/__init__.py', '__version__ = "0.33"\n')
        archive.writestr('elftools/elf/__init__.py', '')
        archive.writestr('elftools/elf/elffile.py', 'class ELFFile: pass\n')
        archive.writestr('pyelftools-0.33.dist-info/METADATA', 'fixture')
        if extra:
            archive.writestr(extra, 'unexpected')
    return buffer.getvalue()


class DependencyTests(unittest.TestCase):
    def setUp(self):
        self.old_path = sys.path[:]
        self.old_modules = {k: v for k, v in sys.modules.items() if k == 'elftools' or k.startswith('elftools.')}
        self.temp = tempfile.TemporaryDirectory()
        self.cache = Path(self.temp.name) / 'cache with spaces'
        self.target = self.cache / 'pyelftools-0.33'
        self.target.mkdir(parents=True)
        self.data = fixture()
        self.pin = patch.object(deps, 'SHA256', hashlib.sha256(self.data).hexdigest())
        self.pin.start()
        self.sleep = patch.object(deps.time, 'sleep')
        self.sleep.start()

    def tearDown(self):
        self.pin.stop()
        self.sleep.stop()
        for name in list(sys.modules):
            if name == 'elftools' or name.startswith('elftools.'):
                del sys.modules[name]
        sys.modules.update(self.old_modules)
        sys.path[:] = self.old_path
        self.temp.cleanup()

    def ensure(self, offline=False):
        with contextlib.redirect_stdout(io.StringIO()):
            deps.ensure(self.cache, offline)

    def test_verified_download_and_import(self):
        with patch.object(deps.urllib.request, 'urlopen', return_value=io.BytesIO(self.data)) as download:
            self.ensure()
        download.assert_called_once_with(deps.URL, timeout=60)
        self.assertTrue((self.target / 'elftools/elf/elffile.py').is_file())
        self.assertFalse((self.target / 'pyelftools-0.33.dist-info').exists())
        self.assertTrue(deps.existing_reader())

    def test_cached_offline_repairs_partial_modules(self):
        (self.cache / deps.WHEEL).write_bytes(self.data)
        (self.target / 'elftools').mkdir()
        (self.target / 'elftools/__init__.py').write_text('broken')
        with patch.object(deps.urllib.request, 'urlopen', side_effect=AssertionError('Network forbidden')):
            self.ensure(True)
        self.assertTrue(deps.existing_reader())

    def test_damaged_cache_rejected_offline(self):
        (self.cache / deps.WHEEL).write_bytes(b'damaged')
        with patch.object(deps.urllib.request, 'urlopen', side_effect=AssertionError('Network forbidden')):
            with self.assertRaisesRegex(RuntimeError, 'without -NoDownload'):
                self.ensure(True)
        self.assertFalse((self.target / 'elftools').exists())

    def test_bad_download_cannot_install(self):
        with patch.object(deps.urllib.request, 'urlopen', side_effect=lambda *a,**k: io.BytesIO(b'not the pinned wheel')) as download:
            with self.assertRaisesRegex(RuntimeError, 'SHA-256'):
                self.ensure()
        self.assertEqual(download.call_count, 3)
        self.assertFalse((self.target / 'elftools').exists())

    def test_partial_download_recovers(self):
        with patch.object(deps.urllib.request, 'urlopen', side_effect=[OSError('connection reset'),io.BytesIO(b'truncated'),io.BytesIO(self.data)]) as download:
            self.ensure()
        self.assertEqual(download.call_count, 3)
        self.assertTrue(deps.existing_reader())

    def test_existing_legacy_cache_needs_no_network(self):
        self.target.rmdir()
        with patch.object(deps, 'existing_reader', return_value=True), patch.object(deps.urllib.request, 'urlopen', side_effect=AssertionError('Network forbidden')):
            self.ensure(True)
        self.assertFalse((self.cache / deps.WHEEL).exists())

    def test_archive_path_traversal_rejected(self):
        for name in ('../outside.py', '/outside.py', 'elftools/../../outside.py', 'C:/outside.py'):
            with self.subTest(name=name):
                data = fixture(name)
                (self.cache / deps.WHEEL).write_bytes(data)
                with patch.object(deps, 'SHA256', hashlib.sha256(data).hexdigest()):
                    with self.assertRaisesRegex(RuntimeError, 'Unsafe path'):
                        self.ensure(True)
        self.assertFalse((self.cache.parent / 'outside.py').exists())


if __name__ == '__main__':
    unittest.main()
