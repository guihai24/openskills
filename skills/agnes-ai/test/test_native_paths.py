#!/usr/bin/env python3
"""Cross-platform path conversion regressions for Agnes media helpers."""

import importlib.util
import os
from pathlib import Path
import unittest
from unittest import mock


BIN = Path(__file__).resolve().parents[1] / "bin"


def load(name):
    spec = importlib.util.spec_from_file_location(name, BIN / (name + ".py"))
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class NativePathTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.modules = [load("_image"), load("_video")]

    def test_posix_absolute_paths_are_preserved(self):
        for module in self.modules:
            with self.subTest(module=module.__name__), mock.patch.object(
                os, "name", "posix"
            ):
                self.assertEqual(
                    module._to_native_path("/Users/test/input.png"),
                    "/Users/test/input.png",
                )
                self.assertEqual(
                    module._to_native_path("/var/tmp/output.png"),
                    "/var/tmp/output.png",
                )
                self.assertEqual(
                    module._to_native_path("/tmp/output.png"),
                    "/tmp/output.png",
                )

    def test_msys_drive_paths_are_converted_by_windows_python(self):
        for module in self.modules:
            with self.subTest(module=module.__name__), mock.patch.object(
                os, "name", "nt"
            ):
                self.assertEqual(
                    module._to_native_path("/c/Users/test/input.png"),
                    r"C:\Users\test\input.png",
                )
                self.assertEqual(
                    module._to_native_path("images/input.png"),
                    "images/input.png",
                )

    def test_urls_and_data_uris_are_preserved(self):
        refs = [
            "https://example.test/a.png",
            "data:image/png;base64,AAAA",
        ]
        for module in self.modules:
            for ref in refs:
                with self.subTest(module=module.__name__, ref=ref):
                    self.assertEqual(module._to_native_path(ref), ref)


if __name__ == "__main__":
    unittest.main()
