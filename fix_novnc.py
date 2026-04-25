#!/usr/bin/env python3
import os

path = "/opt/noVNC/app/ui.js"
with open(path) as f:
    c = f.read()

c = c.replace(
    'document.getElementById("noVNC_clipboard_button")\n            .addEventListener',
    'var _cb=document.getElementById("noVNC_clipboard_button");if(_cb)_cb.addEventListener'
)
c = c.replace(
    'document.getElementById("noVNC_clipboard_text")\n            .addEventListener',
    'var _ct=document.getElementById("noVNC_clipboard_text");if(_ct)_ct.addEventListener'
)

with open(path, "w") as f:
    f.write(c)

print("noVNC clipboard bug fixed OK")
