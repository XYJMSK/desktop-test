#!/usr/bin/env python3
"""Patch noVNC app/ui.js to fix clipboard null pointer bug across all versions."""
import re, os

path = "/opt/noVNC/app/ui.js"
if not os.path.exists(path):
    print("WARN: ui.js not found at", path)
    exit(0)

with open(path) as f:
    c = f.read()

original = c

# Pattern: chained call on potentially-null element
# e.g. document.getElementById("noVNC_clipboard_button")
#              .addEventListener('click', ...);
patches = [
    (
        'document.getElementById("noVNC_clipboard_button")\n            .addEventListener',
        'var _cb=document.getElementById("noVNC_clipboard_button");if(_cb)_cb.addEventListener'
    ),
    (
        'document.getElementById("noVNC_clipboard_text")\n            .addEventListener',
        'var _ct=document.getElementById("noVNC_clipboard_text");if(_ct)_ct.addEventListener'
    ),
    (
        "document.getElementById('noVNC_clipboard_button')\n            .addEventListener",
        "var _cb=document.getElementById('noVNC_clipboard_button');if(_cb)_cb.addEventListener"
    ),
    (
        "document.getElementById('noVNC_clipboard_text')\n            .addEventListener",
        "var _ct=document.getElementById('noVNC_clipboard_text');if(_ct)_ct.addEventListener"
    ),
]

count = 0
for old, new in patches:
    if old in c:
        c = c.replace(old, new)
        count += 1
        print(f"PATCHED: clipboard {old[:40]}...")

if count > 0:
    with open(path, "w") as f:
        f.write(c)
    print(f"OK: {count} patches applied")
else:
    print("INFO: No patches needed (clipboard already safe or different structure)")
