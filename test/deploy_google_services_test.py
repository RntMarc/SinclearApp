#!/usr/bin/env python3
"""Selbstcheck: deploy.py schreibt google-services.json aus der .env.

Ausführen: python3 test/deploy_google_services_test.py
"""

import contextlib
import io
import json
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import deploy  # noqa: E402


class SyncGoogleServicesTest(unittest.TestCase):
    def test_writes_env_values(self):
        env = {
            'FIREBASE_API_KEY': 'rotated-key',
            'FIREBASE_APP_ID': '1:42:android:abc',
            'FIREBASE_MESSAGING_SENDER_ID': '42',
            'FIREBASE_PROJECT_ID': 'demo-project',
        }

        with tempfile.TemporaryDirectory() as tmp:
            target = Path(tmp) / 'google-services.json'
            with mock.patch.object(deploy, 'GOOGLE_SERVICES', target), \
                    contextlib.redirect_stdout(io.StringIO()):
                deploy.sync_google_services(env)
            data = json.loads(target.read_text(encoding='utf-8'))

        self.assertEqual(
            '42', data['project_info']['project_number']
        )
        self.assertEqual('demo-project', data['project_info']['project_id'])
        self.assertEqual(
            'rotated-key',
            data['client'][0]['api_key'][0]['current_key'],
        )
        self.assertEqual(
            '1:42:android:abc',
            data['client'][0]['client_info']['mobilesdk_app_id'],
        )


if __name__ == '__main__':
    unittest.main()
