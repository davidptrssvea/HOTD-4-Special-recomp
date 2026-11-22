import contextlib
import hashlib
import importlib.util
import io
import json
from pathlib import Path
import tempfile
import unittest
import urllib.error
from unittest.mock import patch

spec = importlib.util.spec_from_file_location('publisher', Path(__file__).with_name('publish.py'))
publisher = importlib.util.module_from_spec(spec)
spec.loader.exec_module(publisher)

class ReleaseTests(unittest.TestCase):
    def run_release(self, private, *, bad_digest=False, published=False, tag='v1.0.0', prerelease=False):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            (root / 'RELEASE-NOTES.md').write_text('Test release', encoding='utf-8')
            paths = [root / 'builder.zip', root / 'SHA256SUMS.txt']
            for path in paths:
                path.write_bytes(b'test ' + path.name.encode())
            draft = {'id': 1, 'draft': not published, 'assets': [], 'upload_url': 'https://uploads.example/assets{?name}'}
            uploaded = []
            def api(method, path, data=None):
                if path == '/repos/' + publisher.REPO:
                    return {'private': private}
                if method == 'POST':
                    self.assertIs(data['prerelease'], prerelease)
                    self.assertTrue(data['draft'])
                    return draft
                if method == 'PATCH':
                    self.assertEqual(data, {'draft': False, 'prerelease': prerelease})
                    return {'draft': False}
                if method == 'GET':
                    if uploaded:
                        return {'draft': False, 'prerelease': prerelease, 'assets': uploaded, 'html_url': 'https://example/release'}
                    if prerelease:
                        raise urllib.error.HTTPError(path, 404, 'Not found', None, io.BytesIO())
                    return draft
                raise AssertionError((method, path))
            def upload(request, timeout):
                path = paths[len(uploaded)]
                digest = hashlib.sha256(path.read_bytes()).hexdigest()
                asset = {'state': 'uploaded', 'size': path.stat().st_size, 'name': path.name,
                         'digest': 'sha256:' + ('bad' if bad_digest else digest),
                         'browser_download_url': 'https://example/' + path.name}
                uploaded.append(asset)
                return io.BytesIO(json.dumps(asset).encode())
            with patch.object(publisher, 'ROOT', root), \
                 patch.object(publisher, 'TAG', tag), \
                 patch.object(publisher, 'package', return_value=tuple(paths)), \
                 patch.object(publisher, 'api', side_effect=api), \
                 patch.object(publisher.urllib.request, 'urlopen', side_effect=upload), \
                 patch.object(publisher, 'status_write') as write_status, \
                 patch.dict(publisher.os.environ, {'GITHUB_SHA': 'test-commit', 'GITHUB_RUN_ID': '1'}), \
                 patch('sys.argv', ['publish.py']), contextlib.redirect_stdout(io.StringIO()):
                if bad_digest or published:
                    with self.assertRaises(AssertionError):
                        publisher.main()
                    self.assertFalse(write_status.call_args.args[0]['success'])
                else:
                    publisher.main()
                    result = write_status.call_args.args[0]
                    self.assertTrue(result['success'])
                    self.assertIs(result['private'], private)
                    self.assertEqual([asset['name'] for asset in result['assets']], [path.name for path in paths])
                    self.assertIs(result['prerelease'], prerelease)

    def test_private_and_public_repositories(self):
        for private in (True, False):
            with self.subTest(private=private):
                self.run_release(private)

    def test_preview_tag_publishes_as_prerelease(self):
        self.run_release(False, tag='v1.1.0-openxr-preview', prerelease=True)

    def test_bad_asset_digest_is_rejected(self):
        self.run_release(False, bad_digest=True)

    def test_published_release_is_not_replaced(self):
        self.run_release(False, published=True)

    def test_workflow_accepts_both_visibilities_and_requires_tag(self):
        text = (Path(__file__).parents[1] / '.github/workflows/release.yml').read_text(encoding='utf-8-sig')
        self.assertIn("if: startsWith(github.ref, 'refs/tags/')", text)
        self.assertNotIn('repository.private', text)

if __name__ == '__main__':
    unittest.main()
