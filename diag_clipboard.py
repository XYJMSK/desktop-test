#!/usr/bin/env python3
"""Diagnostic script - print exact ui.js clipboard code around line 329."""
import os, re

p = "/opt/noVNC/app/ui.js"
if not os.path.exists(p):
    print("ERROR: ui.js not found at", p)
    exit(1)

with open(p) as f: c = f.read()

# Show version
pkg = "/opt/noVNC/package.json"
if os.path.exists(pkg):
    import json
    with open(pkg) as f: d = json.load(f)
    print("noVNC version:", d.get("version", "unknown"))

lines = c.split('\n')
# Find addClipboardHandlers and print 15 lines around it
found = False
for i, line in enumerate(lines):
    if 'addClipboardHandlers' in line and 'function' in lines[max(0,i-1)]:
        print(f"\n=== addClipboardHandlers (lines {i+1}-{min(len(lines), i+20)}) ===")
        for j in range(max(0, i), min(len(lines), i+20)):
            print(f"  {j+1}: {lines[j]}")
        found = True
        break

if not found:
    print("\naddClipboardHandlers function not found. Searching all clipboard refs:")
    for i, line in enumerate(lines):
        if 'clipboard' in line.lower():
            print(f"  {i+1}: {line.rstrip()}")
